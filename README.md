# NoFlo-Gnome is the NoFlo runtime for the GNOME environment

NoFlo-Gnome a set of tools to help you write applications using the
NoFlo framework and its UI editor (https://github.com/noflo/noflo-ui)
for the Gnome environment.

## How to install

NoFlo-Gnome currently depends on WebSocket support for LibSoup. This
support hasn't made it upstream yet, but a branch is available and
rebased every few week.

To facilitate the installation, a jhbuild moduleset is provided. You
can install all required dependencies with the following command :
```
jhbuild -m https://raw.githubusercontent.com/noflo/noflo-gnome/master/data/noflo-gnome.modules build noflo-gnome
```

To run the noflo-gnome command, just switch to the jhbuild environment :
```
jhbuild shell
```

## How to install existing components :

NoFlo-Gnome is capable of reusing generic NoFlo components. A lot of
components provide features like string processing, simple mathematic
functions, object processing, group processing, etc...

For example, you can install the noflo-strings set of components by
running the following command :

```
noflo-gnome install noflo/noflo-strings
```

The recommended set of component repository to install is the
following :

```
noflo-gnome install noflo/noflo-core noflo/noflo-flow noflo/noflo-math noflo/noflo-objects noflo/noflo-strings
```

## How to create a new application repository :

```
mkdir ~/myapp
cd ~/myapp
noflo-gnome init -n "MyApplicationName"
```

## How to add a custom component to your application repository :

Components need to be listed in order to be visible in the UI.
You can add one with the following command :
```
touch MyComponent.js
noflo-gnome add -c MyComponent.js
```

## How to add a Glade UI file to your application repository :

The Gnome integration layer to NoFlo provides the ability to represent
Glade UI files automatically in the UI. To do so, your Glade file
needs to be listed in the application's manifest.

You can add a Glade file with the following command :
```
noflo-gnome add -u MyGladeFile.glade
```

## How to add a DBus xml description file to your application repository :

To communicate facilitate communication with DBus services, the Gnome
integration layer to NoFlo provides the ability to generate components
automatically from the DBus XML interface description.

You can add an xml description file with the following command :
```
noflo-gnome add -d MyDbusDescription.xml
```

## How to run your application :

Run the application without debugging :
```
noflo-gnome run
```

To run in debug mode with the Flowhub UI :
```
noflo-gnome run -d -u
```

## How to bundle your application into a single file :

Once you're done creating your application and would like to exchange
it with other people, you can do so by creating a bundle (single file
containing all your assets, code, ui files, etc...)

```
noflo-gnome bundle
```
