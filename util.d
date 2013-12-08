/*
 * Voxels is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Voxels is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Voxels; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */
module util;

import std.math;
import std.random;

template limit(T)
{
	T limit(T v, T minV, T maxV)
	{
		if(v < minV)
			return minV;
		if(v > maxV)
			return maxV;
		return v;
	}
}

ubyte convertToUByte(int v)
{
	return cast(ubyte)limit(v, 0, 0xFF);
}

ubyte convertToUByte(float v)
{
	return convertToUByte(cast(int)(v * 0x100));
}

float convertFromUByteToFloat(ubyte v)
{
	return cast(float)v / 0xFF;
}

int ifloor(float v)
{
    static if(true)
    {
        return cast(int)floor(v);
    }
    else
    {
        if(v < 0)
            return -cast(int)-v;
        return cast(int)v;
    }
}

int iceil(float v)
{
    static if(true)
    {
        return cast(int)ceil(v);
    }
    else
    {
        if(v > 0)
            return -cast(int)-v;
        return cast(int)v;
    }
}

float frandom(float min, float max)
{
    return uniform(min, max);
}

float frandom(float max = 1.0)
{
    return frandom(0.0, max);
}

template interpolate(T)
{
	T interpolate(const T t, const T a, const T b)
	{
		return a + t * (b - a);
	}
}

public final class LinkedList(T)
{
    private struct Node
    {
        T data;
        Node* prev, next;
        public this(T data)
        {
            this.data = data;
        }
    }
    private Node* head, tail;

    public this()
    {
        head = null;
        tail = null;
    }

    void addBack(T v)
    {
        Node* newNode = new Node(v);
        newNode.prev = tail;
        newNode.next = null;
        if(tail !is null)
            tail.next = newNode;
        else
            head = newNode;
        tail = newNode;
    }

    void addFront(T v)
    {
        Node* newNode = new Node(v);
        newNode.prev = null;
        newNode.next = head;
        if(head !is null)
            head.prev = newNode;
        else
            tail = newNode;
        head = newNode;
    }

    @property bool empty() const
    {
        return head !is null;
    }

    @property T front()
    {
        assert(head !is null);
        return head.data;
    }

    @property T back()
    {
        assert(tail !is null);
        return tail.data;
    }

    T removeFront()
    {
        assert(head !is null);
        T retval = head.data;
        if(head is tail)
        {
            head = null;
            tail = null;
            return retval;
        }
        head = head.next;
        head.prev = null;
        return retval;
    }

    T removeBack()
    {
        assert(tail !is null);
        T retval = tail.data;
        if(head is tail)
        {
            head = null;
            tail = null;
            return retval;
        }
        tail = tail.next;
        tail.next = null;
        return retval;
    }

    public struct Iterator
    {
        package Node * node = null;
        private LinkedList list = null;
        public this(Node * node, LinkedList list)
        {
            this.node = node;
            this.list = list;
        }

        public ref Iterator opUnary(string op)() if(op == "++")
        {
            if(node is null)
                node = list.head;
            else
                node = node.next;
            return this;
        }

        public ref Iterator opUnary(string op)() if(op == "--")
        {
            if(node is null)
                node = list.tail;
            else
                node = node.next;
            return this;
        }

        public auto ref T opUnary(string op)() if(op == "*")
        {
            return node.data;
        }

        public auto ref T2 opCast(T2 : T)()
        {
            return node.data;
        }

        public bool opEquals(ref const Iterator rt) const
        {
            return rt.node is node;
        }

        public void removeAndGoToNext()
        {
            assert(node !is null);
            if(node.prev == null)
                list.head = node.next;
            else
                node.prev.next = node.next;
            if(node.next == null)
                list.tail = node.prev;
            else
                node.next.prev = node.prev;
            node = node.next;
        }

        public void removeAndGoToPrevious()
        {
            assert(node !is null);
            if(node.prev == null)
                list.head = node.next;
            else
                node.prev.next = node.next;
            if(node.next == null)
                list.tail = node.prev;
            else
                node.next.prev = node.prev;
            node = node.prev;
        }

        public @property bool ended() const
        {
            return node is null;
        }
    }

    @property Iterator begin()
    {
        return Iterator(head, this);
    }
}

public static bool isPrime(uint v)
{
    if(v % 2 == 0)
        return false;
    for(uint i = 3; i < v; i += 2)
    {
        if(v % i == 0)
            return false;
    }
    return true;
}

public static uint primeCeil(uint v) /// Returns: the smallest prime >= v
{
    if(v <= 2)
        return 2;
    if(v % 2 == 0)
        v++;
    while(!isPrime(v))
    {
        v += 2;
    }
    return v;
}

public bool validOpAssignOp(string op)
{
    if(op == "+=")
        return true;
    if(op == "-=")
        return true;
    if(op == "*=")
        return true;
    if(op == "/=")
        return true;
    if(op == "%=")
        return true;
    if(op == "^^=")
        return true;
    if(op == "&=")
        return true;
    if(op == "|=")
        return true;
    if(op == "^=")
        return true;
    if(op == "<<=")
        return true;
    if(op == ">>=")
        return true;
    if(op == ">>>=")
        return true;
    if(op == "~=")
        return true;
    return false;
}

public final class LinkedHashMap(K, V = K)
{
    private struct Node
    {
        K key;
        V value;
        Node* prev, next, hashNext;
        this(K key, V value)
        {
            this.key = key;
            this.value = value;
        }
    }

    private Node* head, tail;
    private Node*[] table;
    private uint lengthInternal = 0;
    private hash_t delegate(K key) hashFn;

    public hash_t _defaultHashFn(K key)
    {
        static if(__traits(compiles, key.opHash()))
            return key.opHash();
        else
        {
            union uType
            {
                K key;
                ubyte[K.sizeof] bytes;
            }
            uType u;
            u.key = key;
            hash_t retval = 0;
            foreach(ubyte b; u.bytes)
            {
                retval *= 9;
                retval += b;
            }
            return retval;
        }
    }

    public static immutable uint defaultCapacity = 31;

    public this(uint capacity = defaultCapacity)
    {
        this(capacity, &_defaultHashFn);
    }

    public this(uint capacity, hash_t delegate(K key) hashFn)
    {
        head = null;
        tail = null;
        table = new Node*[primeCeil(capacity)];
        this.hashFn = hashFn;
    }

    public this(hash_t delegate(K key) hashFn)
    {
        this(defaultCapacity, hashFn);
    }

    private uint hash(K key)
    {
        return cast(uint)hashFn(key) % table.length;
    }

    private Node* getNode(K key)
    {
        return getNode(key, hash(key));
    }

    private Node* getNode(K key, uint h)
    {
        Node* retval = table[h];
        Node** prev = &table[h];
        while(retval !is null)
        {
            if(retval.key == key)
            {
                *prev = retval.hashNext;
                retval.hashNext = table[h];
                table[h] = retval;
                return retval;
            }
            prev = &retval.hashNext;
            retval = retval.hashNext;
        }
        return null;
    }

    private void rehash(uint newSize)
    {
        table = new Node*[newSize];
        for(Node* node = head; node !is null; node = node.next)
        {
            uint h = hash(node.key);
            node.hashNext = table[h];
            table[h] = node;
        }
    }

    public @property uint length()
    {
        return lengthInternal;
    }

    public void rehash()
    {
        if(lengthInternal / table.length > 3)
            rehash(primeCeil(lengthInternal));
    }

    private void checkForRehash()
    {
        if(lengthInternal / table.length >= 6)
        {
            rehash(primeCeil(lengthInternal / 3));
        }
    }

    public static final class KeyNotFoundException : Exception
    {
        public this(string msg, string file = __FILE__, size_t line = __LINE__)
        {
            super(msg, file, line);
        }
    }

    public static V _defaultReturn()
    {
        throw new KeyNotFoundException("the key wasn't found");
    }

    public V get(K key, lazy V defaultReturn = _defaultReturn())
    {
        Node* node = getNode(key);
        if(node is null)
            return defaultReturn;
        return node.value;
    }

    public bool containsKey(K key)
    {
        return getNode(key) !is null;
    }

    public bool set(K key, V value) // Returns: if the key was in the hashtable before
    {
        uint h = hash(key);
        Node* node = getNode(key, h);
        if(node !is null)
        {
            node.value = value;
            return true;
        }
        node = new Node(key, value);
        checkForRehash();
        lengthInternal++;
        node.hashNext = table[h];
        table[h] = node;
        node.prev = tail;
        if(tail !is null)
            tail.next = node;
        else
            head = node;
        node.next = null;
        tail = node;
        return true;
    }


    public V opIndex(K key)
    {
        return get(key);
    }

    public V opIndexAssign(V newValue, K key)
    {
        set(key, newValue);
        return newValue;
    }

    public void opIndexOpAssign(string op)(V arg, K key) if(validOpAssignOp(op))
    {
        V value = get(key);
        mixin("value " ~ op ~ " arg;");
        set(key, value);
    }

    public bool remove(K key) // Returns: if the key was in the hashtable
    {
        uint h = hash(key);
        Node* node = table[h];
        Node** prev = &table[h];
        while(node !is null)
        {
            if(node.key == key)
            {
                *prev = node.hashNext;
                if(node.prev is null)
                    head = node.next;
                else
                    node.prev.next = node.next;
                if(node.next is null)
                    tail = node.prev;
                else
                    node.next.prev = node.prev;
                lengthInternal--;
                return true;
            }
            prev = &node.hashNext;
            node = node.hashNext;
        }
        return false;
    }

    public struct Iterator
    {
        package Node * node = null;
        private LinkedHashMap map = null;
        public this(Node * node, LinkedHashMap map)
        {
            this.node = node;
            this.map = map;
        }

        public ref Iterator opUnary(string op)() if(op == "++")
        {
            if(node is null)
                node = map.head;
            else
                node = node.next;
            return this;
        }

        public ref Iterator opUnary(string op)() if(op == "--")
        {
            if(node is null)
                node = map.tail;
            else
                node = node.prev;
            return this;
        }

        public bool opEquals(ref const(Iterator) rt) const
        {
            return rt.node is node;
        }

        public void removeAndGoToNext()
        {
            assert(node !is null);
            Node* nextNode = node.next;
            map.remove(node.key);
            node = nextNode;
        }

        public void removeAndGoToPrevious()
        {
            assert(node !is null);
            Node* prevNode = node.prev;
            map.remove(node.key);
            node = prevNode;
        }

        public @property K key()
        {
            assert(node !is null);
            return node.key;
        }

        public @property V value()
        {
            assert(node !is null);
            return node.value;
        }

        public @property void key(K key)
        {
            assert(this.node !is null);
            if(key == this.node.key)
                return;
            uint h = map.hash(node.key);
            Node* node = map.table[h];
            Node** prev = &map.table[h];
            while(node !is null)
            {
                if(node is this.node)
                {
                    *prev = node.hashNext;
                    node.key = key;
                    h = map.hash(key);
                    node.hashNext = map.table[h];
                    map.table[h] = node;
                    return;
                }
                prev = &node.hashNext;
                node = node.hashNext;
            }
            assert(false, "iterator's key not found in iterator's map");
        }

        public @property void value(V value)
        {
            assert(node !is null);
            node.value = value;
        }

        public @property bool ended()
        {
            return node is null;
        }
    }

    public @property Iterator begin()
    {
        return Iterator(head, this);
    }
}
