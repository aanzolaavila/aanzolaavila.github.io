+++
title = "Go: Enforce parameter values through the type system"
date = 2026-07-03T15:00:00-05:00
tags = ["go", "types", "bestpractices", "computerscience"]
description = ""
showFullContent = false
readingTime = true
hideComments = true
draft = false
+++

Suppose this is the code of a dependency that you are using, can you guess what
this piece of code constrains you to?
```go
package mypackage

type expensesParam string
type ExpensesParams map[expensesParam]string

const (
  ExpensesGroupId       expensesParam = "group_id"
  ExpensesFriendId      expensesParam = "friend_id"
  ExpensesDatedAfter    expensesParam = "dated_after"
  ExpensesDatedBefore   expensesParam = "dated_before"
  ExpensesUpdatedAfter  expensesParam = "updated_after"
  ExpensesUpdatedBefore expensesParam = "updated_before"
  ExpensesLimit         expensesParam = "limit"
  ExpensesOffset        expensesParam = "offset"
)

func SendExpenses(params ExpensesParams) error {
  // some logic
}
```

The answer is that it will NOT let you use params different from what the code
wants you to, meaning that you can only use what the code wants you to and
nothing else. All at the expense of the type system.

If you try to do `SendExpenses(mypackage.ExpensesParams{expensesParams("will
not"): "work"})`, the compiler will complain with `expensesParam not exported
by package mypackage`.

The only thing you can do is `SendExpenses(mypackage.ExpensesParams{
mypackage.ExpensesFriendId: "15" })`, forcing you to use exposed fields from
the package as keys for the map.

This means that you don't have to worry about messing or mispelling parameters,
and also if you are designing this as a public API, you don't have to validate
if what you are inserting is given correctly, and only finding out when you are
scratching you head on why an API call does not work.

## How does it work?

This works because the `expensesParam` type is private, as you cannot
instantiate any instance of this type outside the current package, meaning that
the only option available is to use the public constants that are defined
inside `mypackage`.

Though you might think that by doing this you could enforce the same by doing
```go
type privateType string
type PublicType privateType

func MyFunc(t PublicType) { }
```
But this would not be the case, as you can just do `MyFunc(PublicType("got
you"))`, since Go does not need to do the entire chain of conversions if the
underlying type is still the same (`string` for this example).

What you should do instead is something like this
```go
type privateType string // can be any underlying type
type PublicType struct { Value privateType }
```
This will allow you to define your own set of constants that are the only valid
options for calling the constrained function. ~~Unless you do some crazy and
unsafe stuff to insert values inside the struct memory space, but you are not
that crazy, are you not?~~.

Keep in mind, that the only case that is valid to instantiate outside the
package is the zero-value for `PublicType`, meaning that you can do just
`PublicType{}`, and `Value` would be set to the zero-value (`""` for this
example), so, either:
- give meaning to it: a `noop` value for example (depends on your use case),
- or handle it appropriately: trigger a custom error.

Doing `type PublicType map[privateType]string` does not have that disadvantage,
but still is as constrained as a map can be (i.e. be empty or `nil`), which can
may make sense or not for your business logic.

## Advantages

This is the approach I used in my [Splitwise
SDK](https://github.com/aanzolaavila/splitwise.go) package. While it is a small
project I developed a while ago (~4 years from the time of this writing), I
find the idea compelling for software in general in public SDK clients (or much
more I believe).

The reason I believe this is valuable is that the type system I was using was a
direct reflection of the public Splitwise API, so the final API call only
needed to do basic setup before sending it out through the network. I avoided a
lot of additional logic just to form the API request, and I also avoided the
use of any DTOs (Data Transfer Object) logic.

Another thing this saves is error handling, if there were a malformation from
the API request it is the SDK's fault: plain and simple.
Because the SDK should also be responsible of ensuring that the API request is
reaching its destination according to the API specification.
This means that errors that are returned are only scoped to the public API
specification, in this case only scoping the errors to each of the HTTP codes.

## Similar example: AWS SDK v2

I have not seen this approach anywhere in the wild or in the industry, but I
have seen similar patterns that are less restrictive in case you want to have
more flexibility, such as the [AWS SDK
v2](https://github.com/aws/aws-sdk-go-v2) package, where you can make the call
wither with the public constants or the concrete string value. I believe it is
in AWS best interests to keep the API flexible enough for anyone to use either
way the end-user sees fit. I would argue that the former is better in the
general case than the latter, but that comes down to the programmer to decide.

```go
type ComparisonOperator string

// Enum values for ComparisonOperator
const (
	ComparisonOperatorEq          ComparisonOperator = "EQ"
	ComparisonOperatorNe          ComparisonOperator = "NE"
	ComparisonOperatorIn          ComparisonOperator = "IN"
	ComparisonOperatorLe          ComparisonOperator = "LE"
	ComparisonOperatorLt          ComparisonOperator = "LT"
	ComparisonOperatorGe          ComparisonOperator = "GE"
	ComparisonOperatorGt          ComparisonOperator = "GT"
	ComparisonOperatorBetween     ComparisonOperator = "BETWEEN"
	ComparisonOperatorNotNull     ComparisonOperator = "NOT_NULL"
	ComparisonOperatorNull        ComparisonOperator = "NULL"
	ComparisonOperatorContains    ComparisonOperator = "CONTAINS"
	ComparisonOperatorNotContains ComparisonOperator = "NOT_CONTAINS"
	ComparisonOperatorBeginsWith  ComparisonOperator = "BEGINS_WITH"
)
```
Taken from [here](https://github.com/aws/aws-sdk-go-v2/blob/main/service/dynamodb/types/enums.go#L167-L184).

To make it more restrictive as I suggest, it would be just a matter of changing
`ComparisonOperator` to `comparisonOperator`.

The disadvantage from this example is that it we can introduce unnoticed bugs
of the comparison operator to the final API call if we misspell it, on the
worst case noticing when the code reaches production. So the better choice would
be to always use the `ComparisonOperator` type, but is that always done by the
programmer?

## Conclusion

Taking leverage on languages that incorporate a strict type system can lead the
programmer to use a public API correctly by only allowing the user to go to the
intended path. I do believe that a good client is the one that saves the
end-user time by forcing him/her to use the correct way rather than expect the
end-user to always read examples from the documentation (if it is any good),
not to mention also to take leverage on the IDE to do autocompletion and the
compiler for correctness.
