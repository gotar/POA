#!/usr/bin/env node

/**
 * Pi Browser Relay
 *
 * Exposes a loopback-only CDP endpoint (http://127.0.0.1:<port>) that forwards all CDP traffic
 * to a Chrome MV3 extension using chrome.debugger.
 *
 * This enables tools like `agent-browser connect http://127.0.0.1:<port>` to control an
 * existing, user-driven Chrome tab without launching Chrome with --remote-debugging-port.
 */

import { createServer } from 'node:http'
import { randomBytes } from 'node:crypto'
import { Buffer } from 'node:buffer'
import WebSocket, { WebSocketServer } from 'ws'

function parseArgs(argv) {
  const out = { host: '127.0.0.1', port: 18792, verbose: false }
  for (let i = 0; i < argv.length; i += 1) {
    const a = argv[i]
    if (a === '--host') out.host = String(argv[i + 1] ?? '').trim() || out.host
    if (a === '--port') out.port = Number.parseInt(String(argv[i + 1] ?? ''), 10) || out.port
    if (a === '--verbose') out.verbose = true
    if (a === '--help' || a === '-h') {
      console.log(`Usage: node server.mjs [--host 127.0.0.1] [--port 18792] [--verbose]`)
      process.exit(0)
    }
  }
  if (!Number.isFinite(out.port) || out.port <= 0 || out.port > 65535) {
    throw new Error(`Invalid --port ${out.port}`)
  }
  return out
}

function rawDataToString(data, encoding = 'utf8') {
  if (typeof data === 'string') return data
  if (Buffer.isBuffer(data)) return data.toString(encoding)
  if (Array.isArray(data)) return Buffer.concat(data).toString(encoding)
  if (data instanceof ArrayBuffer) return Buffer.from(data).toString(encoding)
  return Buffer.from(String(data)).toString(encoding)
}

function isLoopbackAddress(ip) {
  if (!ip) return false
  if (ip === '127.0.0.1') return true
  if (ip.startsWith('127.')) return true
  if (ip === '::1') return true
  if (ip.startsWith('::ffff:127.')) return true
  return false
}

function headerValue(value) {
  if (!value) return undefined
  if (Array.isArray(value)) return value[0]
  return value
}

function rejectUpgrade(socket, status, bodyText) {
  const body = Buffer.from(bodyText)
  socket.write(
    `HTTP/1.1 ${status} ${status === 200 ? 'OK' : 'ERR'}\r\n` +
      'Content-Type: text/plain; charset=utf-8\r\n' +
      `Content-Length: ${body.length}\r\n` +
      'Connection: close\r\n' +
      '\r\n',
  )
  socket.write(body)
  socket.end()
  try {
    socket.destroy()
  } catch {
    // ignore
  }
}

/** @typedef {{id:number, method:string, params?:any, sessionId?:string}} CdpCommand */
/** @typedef {{id:number, result?:any, error?:{message:string}, sessionId?:string}} CdpResponse */
/** @typedef {{method:string, params?:any, sessionId?:string}} CdpEvent */

/** @typedef {{id:number, method:'forwardCDPCommand', params:{method:string, params?:any, sessionId?:string}}} ExtensionForwardCommand */
/** @typedef {{id:number, result?:any, error?:string}} ExtensionResponse */
/** @typedef {{method:'forwardCDPEvent', params:{method:string, params?:any, sessionId?:string}}} ExtensionForwardEvent */

/** @typedef {{targetId:string, type?:string, title?:string, url?:string, attached?:boolean}} TargetInfo */

/** @type {WebSocket|null} */
let extensionWs = null

/** @type {Set<WebSocket>} */
const cdpClients = new Set()

/** @type {Map<string, {sessionId:string, targetId:string, targetInfo:TargetInfo}>} */
const connectedTargets = new Map()

/** @type {Map<number, {resolve:(v:any)=>void, reject:(e:Error)=>void, timer:NodeJS.Timeout}>} */
const pendingExtension = new Map()

let nextExtensionId = 1

async function sendToExtension(payload) {
  const ws = extensionWs
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    throw new Error('Chrome extension not connected')
  }
  ws.send(JSON.stringify(payload))
  return await new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      pendingExtension.delete(payload.id)
      reject(new Error(`extension request timeout: ${payload.params.method}`))
    }, 30_000)
    pendingExtension.set(payload.id, { resolve, reject, timer })
  })
}

function broadcastToCdpClients(evt) {
  const msg = JSON.stringify(evt)
  for (const ws of cdpClients) {
    if (ws.readyState !== WebSocket.OPEN) continue
    ws.send(msg)
  }
}

function sendResponseToCdp(ws, res) {
  if (ws.readyState !== WebSocket.OPEN) return
  ws.send(JSON.stringify(res))
}

function ensureTargetEventsForClient(ws, mode) {
  for (const target of connectedTargets.values()) {
    if (mode === 'autoAttach') {
      ws.send(
        JSON.stringify({
          method: 'Target.attachedToTarget',
          params: {
            sessionId: target.sessionId,
            targetInfo: { ...target.targetInfo, attached: true },
            waitingForDebugger: false,
          },
        }),
      )
    } else {
      ws.send(
        JSON.stringify({
          method: 'Target.targetCreated',
          params: { targetInfo: { ...target.targetInfo, attached: true } },
        }),
      )
    }
  }
}

async function routeCdpCommand(cmd) {
  switch (cmd.method) {
    case 'Browser.getVersion':
      return {
        protocolVersion: '1.3',
        product: 'Chrome/Pi-Browser-Relay',
        revision: '0',
        userAgent: 'Pi-Browser-Relay',
        jsVersion: 'V8',
      }
    case 'Browser.setDownloadBehavior':
      return {}
    case 'Target.setAutoAttach':
    case 'Target.setDiscoverTargets':
      return {}
    case 'Target.getTargets':
      return {
        targetInfos: Array.from(connectedTargets.values()).map((t) => ({
          ...t.targetInfo,
          attached: true,
        })),
      }
    case 'Target.getTargetInfo': {
      const params = cmd.params ?? {}
      const targetId = typeof params.targetId === 'string' ? params.targetId : undefined
      if (targetId) {
        for (const t of connectedTargets.values()) {
          if (t.targetId === targetId) return { targetInfo: t.targetInfo }
        }
      }
      if (cmd.sessionId && connectedTargets.has(cmd.sessionId)) {
        const t = connectedTargets.get(cmd.sessionId)
        if (t) return { targetInfo: t.targetInfo }
      }
      const first = Array.from(connectedTargets.values())[0]
      return { targetInfo: first?.targetInfo }
    }
    case 'Target.attachToTarget': {
      const params = cmd.params ?? {}
      const targetId = typeof params.targetId === 'string' ? params.targetId : undefined
      if (!targetId) throw new Error('targetId required')
      for (const t of connectedTargets.values()) {
        if (t.targetId === targetId) return { sessionId: t.sessionId }
      }
      throw new Error('target not found')
    }
    default: {
      const id = nextExtensionId++
      return await sendToExtension({
        id,
        method: 'forwardCDPCommand',
        params: {
          method: cmd.method,
          sessionId: cmd.sessionId,
          params: cmd.params,
        },
      })
    }
  }
}

const opts = parseArgs(process.argv.slice(2))

// Small random server id (helps debugging multiple instances)
const instanceId = randomBytes(3).toString('hex')

const server = createServer((req, res) => {
  const url = new URL(req.url ?? '/', `http://${opts.host}:${opts.port}`)
  const pathname = url.pathname

  if (req.method === 'HEAD' && pathname === '/') {
    res.writeHead(200)
    res.end()
    return
  }

  if (pathname === '/') {
    res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' })
    res.end('OK')
    return
  }

  if (pathname === '/extension/status') {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify({ connected: Boolean(extensionWs) }))
    return
  }

  const hostHeader = (req.headers.host?.trim() || `${opts.host}:${opts.port}`).replace(/\s+/g, '')
  const wsHost = `ws://${hostHeader}`
  const cdpWsUrl = `${wsHost}/cdp`

  if ((pathname === '/json/version' || pathname === '/json/version/') && req.method === 'GET') {
    const payload = {
      Browser: 'Pi/extension-relay',
      'Protocol-Version': '1.3',
      ...(extensionWs ? { webSocketDebuggerUrl: cdpWsUrl } : {}),
    }
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify(payload))
    return
  }

  const listPaths = new Set(['/json', '/json/', '/json/list', '/json/list/'])
  if (listPaths.has(pathname) && req.method === 'GET') {
    const list = Array.from(connectedTargets.values()).map((t) => ({
      id: t.targetId,
      type: t.targetInfo.type ?? 'page',
      title: t.targetInfo.title ?? '',
      description: t.targetInfo.title ?? '',
      url: t.targetInfo.url ?? '',
      webSocketDebuggerUrl: cdpWsUrl,
      devtoolsFrontendUrl: `/devtools/inspector.html?ws=${cdpWsUrl.replace('ws://', '')}`,
    }))
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify(list))
    return
  }

  const activateMatch = pathname.match(/^\/json\/activate\/(.+)$/)
  if (activateMatch && req.method === 'GET') {
    const targetId = decodeURIComponent(activateMatch[1] ?? '').trim()
    if (!targetId) {
      res.writeHead(400)
      res.end('targetId required')
      return
    }
    ;(async () => {
      try {
        await sendToExtension({
          id: nextExtensionId++,
          method: 'forwardCDPCommand',
          params: { method: 'Target.activateTarget', params: { targetId } },
        })
      } catch {
        // ignore
      }
    })()
    res.writeHead(200)
    res.end('OK')
    return
  }

  const closeMatch = pathname.match(/^\/json\/close\/(.+)$/)
  if (closeMatch && req.method === 'GET') {
    const targetId = decodeURIComponent(closeMatch[1] ?? '').trim()
    if (!targetId) {
      res.writeHead(400)
      res.end('targetId required')
      return
    }
    ;(async () => {
      try {
        await sendToExtension({
          id: nextExtensionId++,
          method: 'forwardCDPCommand',
          params: { method: 'Target.closeTarget', params: { targetId } },
        })
      } catch {
        // ignore
      }
    })()
    res.writeHead(200)
    res.end('OK')
    return
  }

  res.writeHead(404)
  res.end('not found')
})

const wssExtension = new WebSocketServer({ noServer: true })
const wssCdp = new WebSocketServer({ noServer: true })

server.on('upgrade', (req, socket, head) => {
  const url = new URL(req.url ?? '/', `http://${opts.host}:${opts.port}`)
  const pathname = url.pathname

  const remote = req.socket.remoteAddress
  if (!isLoopbackAddress(remote)) {
    rejectUpgrade(socket, 403, 'Forbidden')
    return
  }

  const origin = headerValue(req.headers.origin)
  // Allow:
  // - extension WS: chrome-extension://...
  // - CDP clients: no Origin header
  if (origin && !String(origin).startsWith('chrome-extension://')) {
    rejectUpgrade(socket, 403, 'Forbidden: invalid origin')
    return
  }

  if (pathname === '/extension') {
    if (extensionWs) {
      rejectUpgrade(socket, 409, 'Extension already connected')
      return
    }
    wssExtension.handleUpgrade(req, socket, head, (ws) => {
      wssExtension.emit('connection', ws, req)
    })
    return
  }

  if (pathname === '/cdp') {
    if (!extensionWs) {
      rejectUpgrade(socket, 503, 'Extension not connected')
      return
    }
    wssCdp.handleUpgrade(req, socket, head, (ws) => {
      wssCdp.emit('connection', ws, req)
    })
    return
  }

  rejectUpgrade(socket, 404, 'Not Found')
})

wssExtension.on('connection', (ws) => {
  extensionWs = ws
  if (opts.verbose) console.log(`[relay ${instanceId}] extension connected`)

  const ping = setInterval(() => {
    if (ws.readyState !== WebSocket.OPEN) return
    ws.send(JSON.stringify({ method: 'ping' }))
  }, 5000)

  ws.on('message', (data) => {
    let parsed = null
    try {
      parsed = JSON.parse(rawDataToString(data))
    } catch {
      return
    }

    // Response to an earlier forwarded command
    if (parsed && typeof parsed.id === 'number' && (parsed.result !== undefined || parsed.error !== undefined)) {
      const pending = pendingExtension.get(parsed.id)
      if (!pending) return
      pendingExtension.delete(parsed.id)
      clearTimeout(pending.timer)
      if (typeof parsed.error === 'string' && parsed.error.trim()) pending.reject(new Error(parsed.error))
      else pending.resolve(parsed.result)
      return
    }

    // Forwarded CDP event from extension
    if (parsed && parsed.method === 'pong') return
    if (!parsed || parsed.method !== 'forwardCDPEvent') return

    const method = parsed.params?.method
    const params = parsed.params?.params
    const sessionId = parsed.params?.sessionId
    if (!method || typeof method !== 'string') return

    if (method === 'Target.attachedToTarget') {
      const attached = params ?? {}
      const targetType = attached?.targetInfo?.type ?? 'page'
      if (targetType === 'page' && attached?.sessionId && attached?.targetInfo?.targetId) {
        const prev = connectedTargets.get(attached.sessionId)
        const nextTargetId = attached.targetInfo.targetId
        const prevTargetId = prev?.targetId
        const changedTarget = Boolean(prev && prevTargetId && prevTargetId !== nextTargetId)

        connectedTargets.set(attached.sessionId, {
          sessionId: attached.sessionId,
          targetId: nextTargetId,
          targetInfo: attached.targetInfo,
        })

        if (changedTarget && prevTargetId) {
          broadcastToCdpClients({
            method: 'Target.detachedFromTarget',
            params: { sessionId: attached.sessionId, targetId: prevTargetId },
            sessionId: attached.sessionId,
          })
        }

        if (!prev || changedTarget) {
          broadcastToCdpClients({ method, params, sessionId })
        }
        return
      }
    }

    if (method === 'Target.detachedFromTarget') {
      const detached = params ?? {}
      if (detached?.sessionId) connectedTargets.delete(detached.sessionId)
      broadcastToCdpClients({ method, params, sessionId })
      return
    }

    // Keep cached URL/title up to date for /json/list
    if (method === 'Target.targetInfoChanged') {
      const changed = params ?? {}
      const targetInfo = changed?.targetInfo
      const targetId = targetInfo?.targetId
      if (targetId && (targetInfo?.type ?? 'page') === 'page') {
        for (const [sid, target] of connectedTargets) {
          if (target.targetId !== targetId) continue
          connectedTargets.set(sid, { ...target, targetInfo: { ...target.targetInfo, ...(targetInfo || {}) } })
        }
      }
    }

    broadcastToCdpClients({ method, params, sessionId })
  })

  ws.on('close', () => {
    if (opts.verbose) console.log(`[relay ${instanceId}] extension disconnected`)
    clearInterval(ping)
    extensionWs = null

    for (const [, pending] of pendingExtension) {
      clearTimeout(pending.timer)
      pending.reject(new Error('extension disconnected'))
    }
    pendingExtension.clear()
    connectedTargets.clear()

    for (const client of cdpClients) {
      try {
        client.close(1011, 'extension disconnected')
      } catch {
        // ignore
      }
    }
    cdpClients.clear()
  })
})

wssCdp.on('connection', (ws) => {
  cdpClients.add(ws)
  if (opts.verbose) console.log(`[relay ${instanceId}] CDP client connected (clients=${cdpClients.size})`)

  ws.on('message', async (data) => {
    /** @type {CdpCommand|null} */
    let cmd = null
    try {
      cmd = JSON.parse(rawDataToString(data))
    } catch {
      return
    }
    if (!cmd || typeof cmd !== 'object') return
    if (typeof cmd.id !== 'number' || typeof cmd.method !== 'string') return

    if (!extensionWs) {
      sendResponseToCdp(ws, { id: cmd.id, sessionId: cmd.sessionId, error: { message: 'Extension not connected' } })
      return
    }

    try {
      const result = await routeCdpCommand(cmd)

      // Help some clients bootstrap target discovery/attachment.
      if (cmd.method === 'Target.setAutoAttach' && !cmd.sessionId) {
        ensureTargetEventsForClient(ws, 'autoAttach')
      }
      if (cmd.method === 'Target.setDiscoverTargets') {
        const discover = cmd.params ?? {}
        if (discover.discover === true) ensureTargetEventsForClient(ws, 'discover')
      }
      if (cmd.method === 'Target.attachToTarget') {
        const params = cmd.params ?? {}
        const targetId = typeof params.targetId === 'string' ? params.targetId : undefined
        if (targetId) {
          const target = Array.from(connectedTargets.values()).find((t) => t.targetId === targetId)
          if (target) {
            ws.send(
              JSON.stringify({
                method: 'Target.attachedToTarget',
                params: {
                  sessionId: target.sessionId,
                  targetInfo: { ...target.targetInfo, attached: true },
                  waitingForDebugger: false,
                },
              }),
            )
          }
        }
      }

      /** @type {CdpResponse} */
      const response = { id: cmd.id, sessionId: cmd.sessionId, result }
      sendResponseToCdp(ws, response)
    } catch (err) {
      sendResponseToCdp(ws, {
        id: cmd.id,
        sessionId: cmd.sessionId,
        error: { message: err instanceof Error ? err.message : String(err) },
      })
    }
  })

  ws.on('close', () => {
    cdpClients.delete(ws)
    if (opts.verbose) console.log(`[relay ${instanceId}] CDP client disconnected (clients=${cdpClients.size})`)
  })
})

await new Promise((resolve, reject) => {
  server.listen(opts.port, opts.host, () => resolve())
  server.once('error', reject)
})

const baseUrl = `http://${opts.host}:${opts.port}`

console.log(`[pi-browser-relay ${instanceId}] listening on ${baseUrl}`)
console.log(`[pi-browser-relay ${instanceId}] extension WS: ws://${opts.host}:${opts.port}/extension`)
console.log(`[pi-browser-relay ${instanceId}] CDP WS: ws://${opts.host}:${opts.port}/cdp (available after attaching a tab)`) 
console.log('')
console.log('Next steps:')
console.log(`1) Load the extension (unpacked) from: ${new URL('./extension/', import.meta.url).pathname}`)
console.log('2) In Chrome, click the extension icon on a tab to attach (badge ON).')
console.log(`3) Connect your automation tool: agent-browser connect ${baseUrl}`)

process.on('SIGINT', () => {
  console.log(`\n[pi-browser-relay ${instanceId}] shutting down...`)
  try {
    extensionWs?.close(1001, 'server stopping')
  } catch {
    // ignore
  }
  for (const ws of cdpClients) {
    try {
      ws.close(1001, 'server stopping')
    } catch {
      // ignore
    }
  }
  server.close(() => process.exit(0))
})
