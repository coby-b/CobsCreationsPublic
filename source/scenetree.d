/**
 *  file scenetree.d
 *  Manages a hierarchical scene graph of GameObject instances
 */
module scenetree;

import gameobject, gameapplication;

/**
 *  Class SceneObject
 *  Wraps a GameObject and its child nodes for scene hierarchy
 */
class SceneObject {
    /** The associated GameObject */
    GameObject obj;
    /** Child SceneObject nodes */
    SceneObject[] children;

    /**
     *  Construct a SceneObject wrapper
     *  Params:
     *      Obj = GameObject to wrap
     */
    this(GameObject Obj) {
        obj = Obj;
    }

    /**
     *  Add a child node to this SceneObject
     *  Params:
     *      child = SceneObject to add as a child
     */
    void addChild(SceneObject child) {
        children ~= child;
    }

    /**
     *  Traverse this node and all descendants in depth‐first order
     *  Params:
     *      func = Delegate to invoke for each non-null GameObject
     */
    void traverse(void delegate(GameObject) func) {
        if (obj !is null) {
            func(obj);
        }
        foreach (child; children) {
            child.traverse(func);
        }
    }
}

/**
 *  Class SceneTree
 *  Holds all SceneObject nodes under a dummy root for scene traversal
 */
class SceneTree {
    /** Dummy root node whose obj is always null */
    SceneObject rootObject;

    /** Construct an empty SceneTree with a null root */
    this() {
        rootObject = new SceneObject(null);
    }

    /**
     *  Add a GameObject to the root of the scene graph
     *  Params:
     *      obj = GameObject to add
     */
    void addObject(GameObject obj) {
        rootObject.addChild(new SceneObject(obj));
    }

    /**
     *  Traverse every GameObject in the scene graph
     *  Params:
     *      func = Delegate to invoke on each GameObject
     */
    void traverseTree(void delegate(GameObject) func) {
        rootObject.traverse(func);
    }
}