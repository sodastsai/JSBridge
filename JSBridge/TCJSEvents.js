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
var EventEmitter = (function () {
    function EventEmitter() {
        this._maxListeners = 0;
        this._listeners = {};
    }
    EventEmitter.prototype._getListenerList = function (event) {
        var listenerList = this._listeners[event];
        if (typeof listenerList === "undefined") {
            this._listeners[event] = listenerList = [];
        }
        return listenerList;
    };
    EventEmitter.prototype._addEventListener = function (event, listener, el) {
        this.emit("newListener", event, el ? el : listener);
        this._getListenerList(event).push(listener);
        if (this._maxListeners !== 0 && this._maxListeners !== Infinity &&
            this.listenerCount(event) > this._maxListeners) {
            var msg = "The number of listeners exceeds";
            console.warn(msg);
            application.console.warn(msg);
        }
        return this;
    };
    EventEmitter.prototype.addEventListener = function (event, listener) {
        return this._addEventListener(event, listener);
    };
    EventEmitter.prototype.on = function (event, listener) {
        return this._addEventListener(event, listener);
    };
    EventEmitter.prototype.once = function (event, listener) {
        var thisEventEmitter = this;
        function callback() {
            listener.apply(this, arguments);
            thisEventEmitter.removeEventListener(event, callback);
        }
        return this._addEventListener(event, callback, listener);
    };
    EventEmitter.prototype.removeEventListener = function (event, listener) {
        var listenerList = this._getListenerList(event);
        var indexToRemove = -1;
        for (var i = 0; i < listenerList.length; ++i) {
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
    };
    EventEmitter.prototype.removeAllListeners = function (event) {
        if (typeof event === "undefined") {
            this._listeners = {};
        }
        else {
            this._listeners[event] = [];
        }
        return this;
    };
    EventEmitter.prototype.setMaxListeners = function (count) {
        this._maxListeners = count;
        return this;
    };
    EventEmitter.prototype.getMaxListeners = function () {
        return this._maxListeners;
    };
    EventEmitter.prototype.listenerCount = function (event) {
        return this._getListenerList(event).length;
    };
    EventEmitter.prototype.emit = function (event) {
        var args = [];
        for (var _i = 1; _i < arguments.length; _i++) {
            args[_i - 1] = arguments[_i];
        }
        var listeners = this._getListenerList(event);
        for (var i = 0; i < listeners.length; i++) {
            listeners[i].apply(this, args);
        }
        return listeners.length !== 0;
    };
    return EventEmitter;
})();
exports.EventEmitter = EventEmitter;
