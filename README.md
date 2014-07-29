# NoFlo-Gnome is the NoFlo runtime for the GNOME environment

NoFlo-Gnome a set of tools to help you write applications using the
NoFlo framework and its UI editor (https://github.com/noflo/noflo-ui)
for the Gnome environment.

## How to create a new application repository :

```
mkdir ~/myapp
cd ~/myapp
noflo-gnome init -n "MyApplicationName"
```

## How to add a custom component to your application repository :

```
touch MyComponent.js
noflo-gnome add -c MyComponent.js
```

## How to add a Glade UI file to your application repository :

```
noflo-gnome add -u MyGladeFile.glade
```

## How to add a DBus xml description file to your application repository :

```
noflo-gnome add -d MyDbusDescription.xml
```

## How to run your application :

```
noflo-gnome run
```

To run in debug mode with the Flowhub UI :
```
noflo-gnome run -d -u
```

## How to bundle your application into a single file :

Once you're done creating you application and would like to exchange
it with other people, you can do so by creating a bundle (single file
containing all your assets, code, ui files, etc...)

```
noflo-gnome bundle
```
