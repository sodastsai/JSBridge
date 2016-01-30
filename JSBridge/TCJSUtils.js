module.exports.inherits = function(Constructor, SuperConstructor) {
    Object.setPrototypeOf(Constructor.prototype, SuperConstructor.prototype);
    Constructor.super_ = SuperConstructor;
};
