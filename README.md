# POA - Polska Organizacja Aikido

This site use static generator built upon [dry-system][dry-system], [rom-rb][rom-rb], and [dry-view][dry-view].

[dry-system]: http://dry-rb.org/gems/dry-system
[rom-rb]: http://rom-rb.org/
[dry-view]: http://dry-rb.org/gems/dry-view

## Getting started

Run `./bin/setup` to set up the application.

Review `.env` and adjust the settings as required.

## Building the site

Run `./bin/build` to build the site. This will empty the `build/` directory and then repopulate it with a new copy of the site's files.

## Structure

### System

The application is managed by [dry-system][dry-system] (which is set up in the `system/` dir). The system manages the classes defined in `lib/site/` and populates a container for returning instances of these classes, ready to use. It also provides an `Import` mixin for declaring dependencies to be injected into these instances, which makes object composition easy and allows for application logic to be broken down into smaller, more focused units.

In this application, the system provides two special components:

- `settings`, which provides the settings defined in `system/boot/settings.rb`, loaded from either `.env` or the `ENV`
- `database`, which creates an in-memory SQLite database and migrates it according to the schemas defined in `lib/database/relations/`

### Persistence

The persystence layer is built using [rom-rb][rom-rb] and is a crucial aspect of the application. It gives us a database that we can populate from any number of sources, and then use to extract and combine data in ways that are meaningful to the types of pages we want to generate for our site.

The system's `database` component (see above) loads **relations** (which roughly correspond to database tables in typical use) in `lib/database/relations`.

The relations also provide a place for defining low-level query logic. We can then use this logic when building **repositories** (see `lib/site/repos/`), which provide the application's own clear, central interface to the persistence layer. Repositories give us a place to define meaningful names for the data we wish to access, and then return typed, immutable structs that can be passed around the application and used as required.

We can add extra beavior to these structs by defining our own custom struct classes in the repositories' struct namespace, `Site::Entities` (see `lib/site/entities/`, and also `lib/site/repo.rb` for where the `struct_namespace` is configured).

### Build components

The application offers 2 key build stages, **prepare** and **generate**, which are run in sequence when building the static site.

The prepare stage (see `lib/site/prepare.rb`) is intended for us to populate the database with any data we require for our site. Here we can run number of different **importers** to prepare the data we need.

The generate stage (see `lib/site/generate.rb`) is intended for us to fetch data back from the database as required, render views, and save the output as static files.

### Views

Views are rendered using [dry-view][dry-view]. dry-view allow us to define our own **view controllers** that work with injected dependencies (using our system's `Import` module) from across the application to prepare data and then explicitly expose it to the view template. Every value exposed to the template can be decorated in a **view part**, which gives us a place to properly encapsulte view-specific logic for the various entities in our application.

In this particular application, views are defined in `lib/site/views/`, and view parts in `lib/site/view/parts`. See `lib/site/views/writing.rb` for a view controller that works with a repository and exposes data to the template wrapped in custom view parts.

Views also come with a **context**, which establishes a baseline rendering environment and provides logic to both the templates and view parts. In this application, the context is defined in `lib/site/view/context.rb`. It currently exposes site-specific settings, like the title, author, and URL, allows us to manage a page title (for setting a page title from within each template) and a current path (for determining which item in the site nav to style as "active").

## Extending the application

Since each application layer serves a clear purpose and their various components are general purpose and etensible, adding new behaviour becomes simple: add your own relations, entities, views, or view parts; build another loader; decorate the immutable data that is passed around; add your own components and use the `Import` mixin to express complex behaviour from many simple parts.

Extending the application doesn't require any special framework plugins or monkey patching. This is a plain-and-simple Ruby application that will work with whatever code and whatever gems you like.

