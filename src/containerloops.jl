import Base.keys
import Base.values

## These are the containers that can be looped over
## The suffix 0 is for SortedDict and SortedMultiDict
## The suffix 1 is for SortedSet.  No suffix means any of the
## three.  

typealias SCContainers0 Union(SortedDict, SortedMultiDict)
typealias SCContainers Union(SCContainers0, SortedSet)

@inline extractcontainer(s::SCContainers) = s

## This holds an object describing an exclude-last
## iteration.

abstract AbstractExcludeLast{ContainerType <: SCContainers}

immutable SCExcludeLast0{ContainerType <: SCContainers0} <: AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

immutable SCExcludeLast1{ContainerType <: SortedSet} <: AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

@inline extractcontainer(s::AbstractExcludeLast) = s.m


## This holds an object describing an include-last
## (i.e., colon operator) iteration.

abstract AbstractIncludeLast{ContainerType <: SCContainers}

immutable SCIncludeLast0{ContainerType <: SCContainers0} <: AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end



immutable SCIncludeLast1{ContainerType <: SortedSet} <: AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end

@inline extractcontainer(s::AbstractIncludeLast) = s.m


## The basic iterations are either over the whole sorted container, an
## exclude-last object or include-last object.

typealias SCIterableTypesBase0 Union(SCContainers0,
                                     SCExcludeLast0,
                                     SCIncludeLast0)

typealias SCIterableTypesBase1 Union(SortedSet,
                                     SCExcludeLast1,
                                     SCIncludeLast1)


typealias SCIterableTypesBase Union(SCContainers,
                                    AbstractExcludeLast,
                                    AbstractIncludeLast)


## The compound iterations are obtained by applying keys(..) or values(..)
## to the basic iterations.  Furthermore, tokens(..) can be applied
## to either a basic iteration or a keys/values iteration.

immutable SCKeyIteration{T <: SCIterableTypesBase0}
    base::T
end

immutable SCValIteration{T <: SCIterableTypesBase0}
    base::T
end

immutable SCTokenIteration0{T <: SCIterableTypesBase0}
    base::T
end

immutable SCTokenIteration1{T <: SCIterableTypesBase1}
    base::T
end


immutable SCTokenKeyIteration{T <: SCIterableTypesBase0}
    base::T
end

immutable SCTokenValIteration{T <: SCIterableTypesBase0}
    base::T
end

typealias SCCompoundIterable Union(SCKeyIteration,
                                   SCValIteration, 
                                   SCTokenIteration0,
                                   SCTokenIteration1,
                                   SCTokenKeyIteration, 
                                   SCTokenValIteration)

@inline extractcontainer(s::SCCompoundIterable) = extractcontainer(s.base)

                                   
typealias SCAllIterable Union(SCIterableTypesBase, SCCompoundIterable)


## All the loops maintain a state which is an object of the
## following type.

immutable SCIterationState
    next::Int
    final::Int
end


## All the loops have the same method for 'done'

@inline done(::SCAllIterable, state::SCIterationState) = state.next == state.final

@inline checkconsistent(i1::Token, i2::Token) =
!(i1.container === i2.container) &&
   throw(ArgumentError("excludelast and colon operator require two tokens for the same container"))


function excludelast{T <: SCContainers0}(i1::Token{T,IntSemiToken}, 
                                         i2::Token{T,IntSemiToken})
    checkconsistent(i1,i2)
    SCExcludeLast0(i1.container, i1.semitoken.address, i2.semitoken.address)
end

function excludelast{T <: SortedSet}(i1::Token{T,IntSemiToken}, 
                                     i2::Token{T,IntSemiToken})
    checkconsistent(i1,i2)
    SCExcludeLast1(i1.container, i1.semitoken.address, i2.semitoken.address)
end

function colon{T <: SCContainers0}(i1::Token{T,IntSemiToken}, 
                                   i2::Token{T,IntSemiToken})
    checkconsistent(i1,i2)
    SCIncludeLast0(i1.container, i1.semitoken.address, i2.semitoken.address)
end

function colon{T <: SortedSet}(i1::Token{T,IntSemiToken}, 
                               i2::Token{T,IntSemiToken})
    checkconsistent(i1,i2)
    SCIncludeLast1(i1.container, i1.semitoken.address, i2.semitoken.address)
end


# Next definition needed to break ambiguity with keys(Associative) from Dict.jl
keys{K, D, Ord <: Ordering}(ba::SortedDict{K,D,Ord}) = SCKeyIteration(ba)
keys{T <: SCIterableTypesBase0}(ba::T) = SCKeyIteration(ba)
# Next definition needed to break ambiguity with keys(Associative) from Dict.jl
values{K, D, Ord <: Ordering}(ba::SortedDict{K,D,Ord}) = SCValIteration(ba)
values{T <: SCIterableTypesBase0}(ba::T) = SCValIteration(ba)
tokens{T <: SCIterableTypesBase0}(ba::T) = SCTokenIteration0(ba)
tokens{T <: SCIterableTypesBase1}(ba::T) = SCTokenIteration1(ba)
tokens{T <: SCIterableTypesBase0}(ki::SCKeyIteration{T}) = SCTokenKeyIteration(ki.base)
tokens{T <: SCIterableTypesBase0}(vi::SCValIteration{T}) = SCTokenValIteration(vi.base)

start(m::SCContainers) = SCIterationState(nextloc0(m.bt,1), 2)

start(e::SCCompoundIterable) = start(e.base)

function start(e::AbstractExcludeLast) 
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
        !(e.pastlast in e.m.bt.useddatacells)) &&
        throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.pastlast) < 0
        return SCIterationState(e.first, e.pastlast) 
    else
        return SCIterationState(2, 2)
    end
end

function start(e::AbstractIncludeLast) 
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
        !(e.last in e.m.bt.useddatacells) || e.last == 2) && 
        throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.last) <= 0
        return SCIterationState(e.first, nextloc0(e.m.bt, e.last)) 
    else
        return SCIterationState(2, 2)
    end
end


## The next function returns different objects depending on whether
## it is a basic iteration, a key iteration, a values iterations,
## a tokens/basic iteration, a tokens/key iteration, or tokens/values
## iteration.

@inline function nexthelper(u, state::SCIterationState)
    sn = state.next
    (sn < 3 || !(sn in extractcontainer(u).bt.useddatacells)) && throw(BoundsError())
    extractcontainer(u).bt.data[sn], sn, 
    SCIterationState(nextloc0(extractcontainer(u).bt, sn), state.final)
end


@inline function next(u::SCIterableTypesBase0, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    (dt.k, dt.d), ni
end

@inline function next(u::SCIterableTypesBase1, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    dt.k, ni
end


@inline function next(u::SCKeyIteration, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    dt.k, ni
end

@inline function next(u::SCValIteration, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    dt.d, ni
end


@inline function next(u::SCTokenIteration0, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    (tokenconstruct(extractcontainer(u), t), (dt.k, dt.d)), ni
end

@inline function next(u::SCTokenIteration1, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    (tokenconstruct(extractcontainer(u), t), dt.k), ni
end

@inline function next(u::SCTokenKeyIteration, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    (tokenconstruct(extractcontainer(u), t), dt.k), ni
end

function next(u::SCTokenValIteration, state::SCIterationState)
    dt, t, ni = nexthelper(u, state)
    (tokenconstruct(extractcontainer(u), t), dt.d), ni
end

empty!(m::SCContainers) =  empty!(m.bt)
length(m::SCContainers) = length(m.bt.data) - length(m.bt.freedatainds) - 2
isempty(m::SCContainers) = length(m) == 0

