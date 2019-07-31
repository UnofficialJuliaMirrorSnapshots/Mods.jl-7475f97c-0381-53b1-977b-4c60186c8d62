module Mods

import Base.isequal, Base.==, Base.+, Base.-, Base.*
import Base.inv, Base./, Base.^
import Base.hash, Base.show

export Mod
export isequal, ==, +, -, *
export is_invertible, inv, /, ^
export hash, CRT

"""
`Mod(v,m)` creates a modular number in mod `m` with value `v%m`.
`Mod(m)` is equivalent to `Mod(0,m)`.
"""
struct Mod{T<:Integer}
    val::T
    mod::T
    function Mod(a::S, m::T) where {S<:Integer, T<:Integer}
        if m < 1
            error("Modulus must be at least 1")
        end

        a,m = promote(a,m)
        return new{typeof(a)}(mod(a,m),m)
    end
end

Mod(m::Integer) = Mod(0,m)

function hash(x::Mod, h::UInt64= UInt64(0))
    v = BigInt(x.val)
    m = BigInt(x.mod)
    return hash(v,hash(m,h))
end

# Test for equality
isequal(x::Mod, y::Mod) = x.mod==y.mod && x.val==y.val
==(x::Mod,y::Mod) = isequal(x,y)

function modcheck(x::Mod, y::Mod)
    if x.mod != y.mod
        error("Cannot operate on two Mod objects with different moduli")
    end
    true
end

# Easy arithmetic
function +(x::Mod, y::Mod)
    modcheck(x,y)
    s,flag = Base.add_with_overflow(x.val,y.val)
    if !flag
        return Mod(x.val+y.val, x.mod)
    end
    s = widen(x.val) + widen(y.val)    # add with added precision
    s = mod(s,x.mod)                   # reduce by modulus
    return Mod(oftype(x.mod,s),x.mod)  # return with proper type
end


function -(x::Mod)
    return Mod(-x.val, x.mod)
end

-(x::Mod,y::Mod) = x + (-y)


function *(x::Mod, y::Mod)
    modcheck(x,y)
    p,flag = Base.mul_with_overflow(x.val,y.val)
    if !flag
        return Mod(x.val*y.val, x.mod)
    end
    p = widemul(x.val, y.val)         # multipy with added precision
    p = mod(p,x.mod)                  # reduce by the modulus
    return Mod(oftype(x.mod,p),x.mod) # return with proper type
end

# Division stuff
"""
`is_invertible(x::Mod)` determines if `x` is invertible.
"""
is_invertible(x::Mod) = return gcd(x.val,x.mod)==1 && x.mod>1

"""
`inv(x::Mod)` gives the multiplicative inverse of `x`.
This may be abbreviated by `x'`.
"""
function inv(x::Mod)
    (g, v, ignore) = gcdx(x.val, x.mod)
    if g != 1 || x.mod==1
        error(x, " is not invertible")
    end
    return Mod(v, x.mod)
end

# Typing shortcut for inv(x)
# adjoint(x::Mod)

function /(x::Mod, y::Mod)
    modcheck(x,y)
    return x * inv(y)
end

function ^(x::Mod, k::Integer)
    if k>0
        return Mod(powermod(x.val, k, x.mod), x.mod)
    end
    if k==0
        T = typeof(x.val)
        return Mod(one(T), x.mod)
    end
    y = inv(x)
    return y^(-k)
end

# Operations with Integers

+(x::Mod, k::Integer) = Mod(k,x.mod)+x
+(k::Integer, x::Mod) = x+k

-(x::Mod, k::Integer) = x + (-k)
-(k::Integer, x::Mod) = (-x) + k

*(x::Mod, k::Integer) = Mod(k,x.mod) * x
*(k::Integer, x::Mod) = x*k

/(x::Mod, k::Integer) = x / Mod(k, x.mod)
/(k::Integer, x::Mod) = Mod(k, x.mod) / x

# Comparison with Integers

isequal(x::Mod, k::Integer) = mod(k,x.mod) == x.val
isequal(k::Integer, x::Mod) = isequal(x,k)
==(x::Mod, k::Integer) = isequal(x,k)
==(k::Integer, x::Mod) = isequal(x,k)

# Chinese remainder theorem functions

# private helper function
function CRT_work(x::Mod, y::Mod)
    n = x.mod
    m = y.mod
    if gcd(n,m) != 1
        error("Moduli must be pairwise relatively prime")
    end

    a = x.val
    b = y.val

    k = inv(Mod(n,m)) * (b-a)

    z = a + k.val*n

    return Mod(z, n*m)
end

# public interface
"""
`CRT(m1,m2,...)`: Chinese Remainder Theorem
```
julia> CRT( Mod(4,11), Mod(8,14) )
Mods.Mod(92,154)

julia> 92%11
4

julia> 92%14
8
```
"""
function CRT(mtuple::Mod...)
    n = length(mtuple)
    if n == 0
        return Mod(1)
    end

    result::Mod = mtuple[1]

    for k=2:n
        result = CRT_work(result,mtuple[k])
    end

    return result
end


show(io::IO, m::Mod) = print(io,"Mod(",m.val,",",m.mod,")")

end # end of module Mods
