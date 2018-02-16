exports.config = {
    // See http://brunch.io/#documentation for docs.
    files: {
        javascripts: {
            // joinTo: "js/app.js"
            joinTo: {
                // "js/uploader.js": "js/uploader.js",
                "js/room-view.js": [
                    "js/uploader.js",
                    "js/room.js",
                    "js/socket.js",
                    "js/file-list.js",
                    "js/upload.js",
                    "js/file.js",
                    "js/file-list-view.js",
                    "js/upload-view.js",
                    "js/file-view.js",
                    "js/presence.js",
                    "js/presence-view.js",
                    "js/room-view.js",
                    "js/async-button-view.js"
                ],
                "js/app.js": /(js\/app\.js|^(?!js))/
            }

            // To use a separate vendor.js bundle, specify two files path
            // http://brunch.io/docs/config#-files-
            // joinTo: {
            //   "js/app.js": /^js/,
            //   "js/vendor.js": /^(?!js)/
            // }
            //
            // To change the order of concatenation of files, explicitly mention here
            // order: {
            //   before: [
            //     "vendor/js/jquery-2.1.1.js",
            //     "vendor/js/bootstrap.min.js"
            //   ]
            // }
        },
        stylesheets: {
            joinTo: "css/app.css"
            /*
              "css/app.css": [
              "css/app.css",
              "css/register.css"
              ]
            */
        },
        templates: {
            joinTo: "js/app.js"
        }
    },

    conventions: {
        // This option sets where we should place non-css and non-js assets in.
        // By default, we set this to "/assets/static". Files in this directory
        // will be copied to `paths.public`, which is "priv/static" by default.
        assets: /^(static)/
    },

    // Phoenix paths configuration
    paths: {
        // Dependencies and current project directories to watch
        watched: ["static", "css", "js", "vendor"],
        // Where to compile files to
        public: "../priv/static"
    },

    // Configure your plugins
    plugins: {
        babel: {
            "presets": [
                ["env", {
                    "useBuiltIns": true
                }]
            ],
            "plugins": [
                ["transform-runtime", {
                    "polyfill": false,
                    "regenerator": true
                }]
            ]
        }
    },

    modules: {
        autoRequire: {
            "js/app.js": ["js/app"]
        }
    },

    npm: {
        enabled: true,
        whitelist: ["phoenix", "phoenix_html", "vue", "babel-runtime"]
    }
};
