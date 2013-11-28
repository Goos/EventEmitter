#EventEmitter

####A simplified way of sending events between anything inheriting from NSObject.

----

Works by swizzling any objects using the `on:` or `emit`-methods, attaching a proxy-object to both sides (the listener *and* the emitter), and swizzling their `dealloc`-method to make sure that listeners don't leak when objects deallocate.

See `Appdelegate.m` for examples.