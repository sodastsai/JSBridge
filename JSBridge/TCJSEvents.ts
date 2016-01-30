//
//  Copyright 2016 Tien-Che Tsai, and Tickle Labs, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

interface IEventEmitterListener {
    (...args: any[]): void;
}

export class EventEmitter {

    private _maxListeners: number = 0;
    private _listeners: any = {};
    private _getListenerList(event: string): IEventEmitterListener[] {
        let listenerList = this._listeners[event];
        if (typeof listenerList === "undefined") {
            this._listeners[event] = listenerList = [];
        }
        return listenerList;
    }

    _addEventListener(event: string, listener: IEventEmitterListener, el?: IEventEmitterListener): EventEmitter {
        this.emit("newListener", event, el ? el : listener);
        this._getListenerList(event).push(listener);
        if (this._maxListeners !== 0 && this._maxListeners !== Infinity &&
            this.listenerCount(event) > this._maxListeners) {
            const msg = "The number of listeners exceeds";
            console.warn(msg);
            application.console.warn(msg);
        }
        return this;
    }
    addEventListener(event: string, listener: IEventEmitterListener): EventEmitter {
        return this._addEventListener(event, listener);
    }
    on(event: string, listener: IEventEmitterListener): EventEmitter {
        return this._addEventListener(event, listener);
    }

    once(event: string, listener: IEventEmitterListener): EventEmitter {
        const thisEventEmitter = this;
        function callback() {
            listener.apply(this, arguments);
            thisEventEmitter.removeEventListener(event, callback);
        }
        return this._addEventListener(event, callback, listener);
    }

    removeEventListener(event: string, listener: IEventEmitterListener): EventEmitter {
        const listenerList = this._getListenerList(event);
        let indexToRemove = -1;
        for (let i = 0; i < listenerList.length; ++i) {
            if (listenerList[i] === listener) {
                indexToRemove = i;
                break;
            }
        }
        if (indexToRemove >= 0) {
            listenerList.splice(indexToRemove, 1);
        }
        this.emit("removeListener", event, listener);
        return this;
    }

    removeAllListeners(event?: string): EventEmitter {
        if (typeof event === "undefined") {
            this._listeners = {};
        } else {
            this._listeners[event] = [];
        }
        return this;
    }

    setMaxListeners(count: number): EventEmitter {
        this._maxListeners = count;
        return this;
    }

    getMaxListeners(): number {
        return this._maxListeners;
    }

    listenerCount(event: string): number {
        return this._getListenerList(event).length;
    }

    emit(event: string, ...args: any[]): boolean {
        const listeners = this._getListenerList(event);
        for (let i = 0; i < listeners.length; i++) {
            listeners[i].apply(this, args);
        }
        return listeners.length !== 0;
    }
}
