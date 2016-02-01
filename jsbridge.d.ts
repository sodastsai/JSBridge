declare const global: any;  // Alias of root object
declare const root: any;  // Alias of root object


// Module --------------------------------------------------------------------------------------------------------------
interface IRequireFunc {
    (path: string): any;
    resolve(path: string): string;
}
interface IModule { // Current module object
    filename: string;  // Readonly, file name of current script. Use this as __filename and __dirname in node.
    loaded: boolean;  // Readonly, indicating whether the script content is loaded of not
    exports: any;  // Exports symbols
    paths: [string];  // Readonly, search paths. The `require` function would find scripts under these paths
    require: IRequireFunc;  // Import/Load other scripts in.
    clearRequireCache();
}
declare const module: IModule;
declare const require: IRequireFunc;  // Import/Load other scripts in.

/* Global Modules
 *
 * * `util`: see `IUtil`.
 * * `fs`: see `IFs`.
 * * `dispatch`: see `IDispatch`.
 * * `events`: see `NEvents`
 * * `underscore`: Check underscore.js 1.8.3 (External, from http://underscorejs.org)
 * * `q`: Check q.js 1.4.1 (External, from https://github.com/kriskowal/q)
 */


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
interface IUtil {  // This interface is used for the exports of `require('util');`
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
    isFunction(obj: any): boolean;

    format(...formats: any[]): string;  // node's format function (`util.format`)
    inspect(obj: any): string;  // node's inspect function (`util.inspect`)

    inherits(constructor: any, superConstructor: any): any; // Returns `constructor`
}


// DataBuffer ----------------------------------------------------------------------------------------------------------
declare namespace DataBuffer {
    function create(length?: number): IDataBuffer
    function fromHexString(hexString: string): IDataBuffer;
    function fromByteArray(byteArray: number[]): IDataBuffer;

    interface IDataBuffer {
        // By changing this field, the content of this data buffer would be also modified.
        // So if you want extend this buffer, just increase the number. (new bytes are filled by 0.)
        // And if you want to reduce the size, just decrease the number. (existed bytes are dropped.)
        length: number;

        byte(): number[];  // Get a number array which represents this buffer
        byte(index: number): number;  // Get a byte at index
        byte(index: number, value: number);  // Set a byte at index by number (0-255)
        byte(index: number, value: string);  // Set a byte at index by hex string ('0'-'ff')

        hexString: string;  // Get hex string representation of this buffer
        equal(dataBuffer: IDataBuffer): boolean;  // Compare the content instead of the object itself

        append(dataBuffer: IDataBuffer);
        delete(start: number, length: number);  // Remove bytes in range
        insert(dataBuffer: IDataBuffer, index: number);  // Insert data buffer at index
        replace(start: number, length: number, dataBuffer: IDataBuffer);

        subDataBuffer(start: number, length: number): IDataBuffer;  // Get subset of data buffer
        copyAsNewDataBuffer(): IDataBuffer;
    }
}


// fs ------------------------------------------------------------------------------------------------------------------
interface IFs {  // This interface is used for the exports of `require('fs');`

    existsSync(path: string): boolean;
    exists(path: string, callback?: (exist: boolean) => void);

    isDirectorySync(path: string): boolean;
    isDirectory(path: string, callback?: (exist: boolean) => void);

    readFile(filename: string, callback?: (data: DataBuffer.IDataBuffer, err: Error) => void);
    writeFile(filename: string, data: DataBuffer.IDataBuffer, callback?: (err: Error) => void);
}


// dispatch ------------------------------------------------------------------------------------------------------------
interface IDispatch {  // This interface is used for the exports of `require('dispatch');`

    /* queue names */
    // Readonly, used to render iOS UI (the `dispatch_get_main_queue()` in iOS)
    // May not be available due to context setting
    uiQueue?: string;
    // Readonly, used to perform IO task (the `DISPATCH_QUEUE_PRIORITY_BACKGROUND` in iOS)
    ioQueue: string;
    // Readonly, used to perform main JavaScript task.
    // (by context settings, default is `dispatch_get_main_queue()`)
    mainQueue: string;
    // Readonly, used to perform non-blocking JavaScript task.
    // (by context settings, default is `DISPATCH_QUEUE_PRIORITY_DEFAULT`)
    backgroundQueue: string;

    /* Note that the `queueName` argument should pass one of above queues */
    async(queueName: string, block: () => void, ...arguments: any[]);
    async(block: () => void, ...arguments: any[]);
}


// Events --------------------------------------------------------------------------------------------------------------
declare namespace NEvents {  // This namespace is used as the exports of `require('events');`
    interface IEventEmitterListener {
        (...args: any[]): void;
    }
    export class EventEmitter {
        addEventListener(event: string, listener: IEventEmitterListener): EventEmitter;
        on(event: string, listener: IEventEmitterListener): EventEmitter;
        once(event: string, listener: IEventEmitterListener): EventEmitter;
        removeEventListener(event: string, listener: IEventEmitterListener): EventEmitter;
        removeAllListeners(event?: string): EventEmitter;
        setMaxListeners(count: number): EventEmitter;
        getMaxListeners(): number;
        listenerCount(event: string): number;
        emit(event: string, ...args: any[]): boolean;
    }
}
