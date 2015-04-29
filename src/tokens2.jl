import Base.isless
import Base.isequal
import Base.colon
import Base.endof

tokenconstruct(m::SortedDict, q::Int) = SDToken(m, IntSemiToken(q))
tokenconstruct(m::SortedMultiDict, q::Int) = SMDToken(m, IntSemiToken(q))
tokenconstruct(m::SortedSet, q::Int) = SetToken(m, IntSemiToken(q))

## Function startof returns the token that points
## to the first sorted order of the tree.  It returns
## the past-end token if the tree is empty.

SortedContainer = Union(SortedDict, SortedMultiDict, SortedSet)
startof(m::SortedContainer) = tokenconstruct(m, beginloc(m.bt))

## Function endof returns the token that points
## to the last item in the sorted order,
## or the before-start marker if the tree is empty.

endof(m::SortedContainer) = tokenconstruct(m, endloc(m.bt))

## Function pastendtoken returns the token past the end of the data.

pastendtoken(m::SortedContainer) = tokenconstruct(m, 2)

## Function beforestarttoken returns the token before the start of the data.

beforestarttoken(m::SortedContainer) = tokenconstruct(m, 1)

## delete! deletes an item given a token.

function delete!(ii::Token)
    has_data(ii)
    delete!(ii.container.bt, ii.semitoken.address)
end


## Function advance takes a token and returns the
## next token in the sorted order. 

function advance(ii::Token)
    not_pastend(ii)
    tokenconstruct(ii.container, nextloc0(ii.container.bt, ii.semitoken.address))
end


## Function regress takes a token and returns the
## previous token in the sorted order. 

function regress(ii::Token)
    not_beforestart(ii)
    tokenconstruct(ii.container, prevloc0(ii.container.bt, ii.semitoken.address))
end


## status of a token is 0 if the token is invalid, 1 if it points to 
## ordinary data, 2 if it points to the before-start location and 3 if
## it points to the past-end location.

status(i::Token) = 
       !(i.semitoken.address in i.container.bt.useddatacells)? 0 :
                        (i.semitoken.address == 1? 2 : (i.semitoken.address == 2? 3 : 1))

function isless(s::Token, t::Token)
    checksamecontainer(s,t)
    return compareInd(s.container.bt, 
                      s.semitoken.address, 
                      t.semitoken.address) < 0
end

function isequal(s::Token, t::Token)
    checksamecontainer(s,t)
    return s.semitoken.address == t.semitoken.address
end


## The next four are correctness-checking routines.  They are
## not exported.

checksamecontainer(s::Token, t::Token) =
!(s.container === t.container) &&
throw(ArgumentError("isless/isequal for tokens requires that the refer to the same container"))

not_beforestart(i::Token) = 
    (!(i.semitoken.address in i.container.bt.useddatacells) || 
     i.semitoken.address == 1) && throw(BoundsError())

not_pastend(i::Token) =
    (!(i.semitoken.address in i.container.bt.useddatacells) || 
     i.semitoken.address == 2) && 
       throw(BoundsError())

has_data(i::Token) =
    (!(i.semitoken.address in i.container.bt.useddatacells) || 
     i.semitoken.address < 3) && 
       throw(BoundsError())

