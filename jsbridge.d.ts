declare const global: any;  // Alias of root object
declare const root: any;  // Alias of root object


// Module --------------------------------------------------------------------------------------------------------------
declare const module: {
    // Current module object
    filename: string;  // Readonly, file name of current script
    loaded: boolean;  // Readonly, indicating whether the script content is loaded of not
    exports: any;  // Exports symbols
    paths: [string];  // Readonly, search paths. The `require` function would find scripts under these paths
    require(path: string): any;  // Import/Load other scripts in.
};
declare const require: (path: string) => any;  // Import/Load other scripts in.


// Application and System ----------------------------------------------------------------------------------------------
declare const application: {
    // An object representing current application
    version: string;  // Verison of current app
    build: string;  // Build number of current app
    identifier: string;  // Identifier of current app

    locale: string;  // Locale of user's current settings
    preferredLanguages: [string];  // Preferred languages of user's current settings

    console: {
        // This console would print messages into the iOS app, instead of the JavaScript console.
        debug(...params: any[]);
        log(...params: any[]);
        info(...params: any[]);
        warn(...params: any[]);
        error(...params: any[]);
    };  // App console
};
declare const system: {
    // An object representing current OS and device
    version: string;  // Version of current OS
    name: string;  // Name of current OS
    model: string;  // Model of current device, like "iPad5,1"
};


// Util ----------------------------------------------------------------------------------------------------------------
interface Util {
    // This interface is used for the exports of `require('util');`

    toString(obj: any): string;

    isRegExp(obj: any): boolean;
    isArray(obj: any): boolean;
    isDate(obj: any): boolean;
    isError(obj: any): boolean;
    isUndefined(obj: any): boolean;
    isNull(obj: any): boolean;
    isNullOrUndefined(obj: any): boolean;
    isBoolean(obj: any): boolean;
    isNumber(obj: any): boolean;
    isString(obj: any): boolean;
    isObject(obj: any): boolean;

    format(...formats: any[]): string;  // node's format function (`util.format`)
    inspect(obj: any): string;  // node's inspect function (`util.inspect`)
}
