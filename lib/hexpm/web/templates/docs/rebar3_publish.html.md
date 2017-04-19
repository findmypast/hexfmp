## Publishing a package

Erlang packages can be published through the [rebar3](http://rebar3.org) Hex plugin. It is suggested to place the entry in the global rebar3 config which should be made as `~/.config/rebar3/rebar.config`.

#### Example rebar.config file

```erlang
{plugins, [rebar3_hex]}.
```

Publishing a package to Hex consists of registering a Hex user, adding metadata to the project's `.app.src` file, and finally submitting the package with a `rebar3` provider.

### Registering a Hex user

When registering a user, you will be prompted for a username, your email and a password. The email is used to confirm your identity during signup, as well as to contact you in case there is an issue with one of your packages. The email will never be shared with a third party.

```nohighlight
$ rebar3 hex user register
Username: johndoe
Email: john.doe@example.com
Password:
Password (confirm):
Registering...
Generating API key...
You are required to confirm your email to access your account, a confirmation email has been sent to john.doe@example.com

```

Once this step has been completed, check your email inbox for the confirmation email. Once you have followed the enclosed link, your account will be ready to use.

### Naming your package

Before publishing, you will have to choose the name of your package. Remember that packages published to Hex are public and can be accessed by anyone in the community. It is also the responsibility of the community to pick and encourage good package names. Here are some tips:

* Avoid using offensive or harassing package names, nicknames, or other identifiers that might detract from a friendly, safe, and welcoming environment for all.
* If you are providing functionality on top of an existing package, consider using that package name as a prefix. For example, if you you are creating a plugin for [Rebar3](https://github.com/erlang/rebar3), consider calling your package `rebar3_plugin` (or `rebar3_somename`) instead of `plugin` (or `somename`).

With a name in hand, it is time to add the proper metadata to your `.app.src` file.

### Adding metadata to `.app.src`

The package is configured in the `.app.src` file. [See below](#example-app-src-file) for an example file. While the dependencies of the application are in `rebar.config`, [as seen below](#example-rebar-config-file) as well.

First, make sure that the `vsn` property is correct. All Hex packages are required to follow [semantic versioning](http://semver.org/). `vsn` and the app name are the only required properties.

Then fill in the `description` property. It should be a sentence, or a few sentences, describing the package. The `description` is optional but highly recommended.

You can also add any of the following to the list of application attributes:


<dl class="dl-horizontal">
  <dt><code>licenses</code></dt>
  <dd>A list of licences the project is licensed under. This attribute is required.</dd>
  <dt><code>pkg_name</code></dt>
  <dd>The name of the package in case you want to publish the package with a different name than the application name.</dd>
  <dt><code>maintainers</code></dt>
  <dd>A list of names (and/or emails) of maintainers to the project. Optional but highly recommended.</dd>
  <dt><code>links</code></dt>
  <dd>A map where the key is a link name and the value is the link URL. Optional but highly recommended.</dd>
  <dt><code>files</code></dt>
  <dd>A list of files and directories to include in the package. Defaults to standard project directories, so you usually don't need to set this property.</dd>
  <dt><code>build_tools</code></dt>
  <dd>List of build tools that can build the package. It's very rare that you need to set this.</dd>
</dl>

#### Dependencies

A dependency defined with no SCM (`git` or `hg`) will be automatically treated as a Hex dependency. See the [Usage guide](/docs/rebar3_usage) for more details.

Only Hex packages will be included as dependencies of the package, for example Git dependencies will not be included. Additionally, only `default` dependencies will be included, just like how rebar3 will only fetch `default` dependencies when fetching the dependencies of your dependencies.

<a id="example-rebar-config-file"></a>

#### Example rebar.config file

```erlang
{deps, [{erlware_commons, "0.15.0"},
        {providers, "1.4.1"},
        {getopt, "0.8.2"},
        {bbmustache, "1.0.3"}
       ]}.

```

<a id="example-app-src-file"></a>

#### Example .app.src file

```erlang
{application, relx,
  [{description, "Release assembler for Erlang/OTP Releases"},
   {vsn, "3.5.0"},
   {modules, []},
   {registered, []},
   {applications, [kernel,
                   stdlib,
                   getopt,
                   erlware_commons,
                   bbmustache,
                   providers]},
   {maintainers, ["Eric Merritt", "Tristan Sloughter",
                  "Jordan Wilberding"]},
   {licenses, ["Apache"]},
   {links, [{"Github", "https://github.com/erlware/relx"}]}]}.

```

### Submitting the package

After the package metadata and dependencies have been added to `.app.src`, we are ready to publish the package with the `rebar3 hex publish` command:

```nohighlight
$ rebar3 hex publish
Publishing relx 3.5.0
  Dependencies:
    bbmustache 1.0.3
    erlware_commons 0.15.0
    getopt 0.8.2
    providers 1.4.1
  Excluded dependencies (not part of the Hex package):

  Included files:
    src/relx.app.src
    src/relx.erl
    src/rlx_app_discovery.erl
    src/rlx_app_info.erl
    src/rlx_cmd_args.erl
    src/...
    include/relx.hrl
    priv/...
    rebar.config
    rebar.lock
    README.md
    LICENSE.md
Proceed? ("Y") Y
Published relx 3.5.0

```

Congratulations, you've published your package! It will appear on the [https://hex.pm](https://hex.pm/) site and will be available to add as a dependency in other rebar3 or mix projects.

Please test your package after publishing by adding it as dependency to a rebar3 project and fetching and compiling it. If there are any issues, you can publish the package again for up to one hour after first publication. A publication can also be reverted with `rebar3 hex publish --revert VERSION`.

When running the command to publish a package, Hex will create a tar file of all the files and directories listed in the `files` property. When the tarball has been pushed to the Hex servers, it will be uploaded to a CDN for fast and reliable access for users. Hex will also recompile the registry file that all clients will update automatically when fetching dependencies.

The [rebar3 hex plugin's documentation](http://www.rebar3.org/v3.0/docs/hex-package-management) contains more information about the hex plugin itself and publishing packages.
