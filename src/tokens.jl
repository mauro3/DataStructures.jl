## Token interface to a container.  A token is the address
## of an item in a container.  The token has two parts: the
## container and the item's address.  The address is of type
## AbstractSemiToken.  


module Tokens


abstract AbstractSemiToken

immutable IntSemiToken <: AbstractSemiToken
    address::Int
end

abstract Token{T, S <: AbstractSemiToken}


## The following two operations extract the two parts of a token.

semi(i::Token) = i.semitoken
container(i::Token) = i.container

export Token
export semi, container


end



