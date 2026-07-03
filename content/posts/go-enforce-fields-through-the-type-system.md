+++
title = "Go: Enforce parameter values through the type system"
date = 2024-03-15T23:07:22-05:00
description = ""
showFullContent = false
readingTime = true
hideComments = true
draft = true
+++

Suppose this is the code of a dependency that you are using, can you guess what this piece of code constrains you to?
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

The answer is that it will NOT let you use params different from what the code wants you to, meaning that you can only use what the code wants you to and nothing else. All at the expense of the type system.

If you try to do `SendExpenses(mypackage.ExpensesParams{expensesParams("will not"): "work"})`, the compiler will complain with `expensesParam not exported by package mypackage`.

The only thing you can do is `SendExpenses(mypackage.ExpensesParams{ mypackage.ExpensesFriendId: "15" })`, forcing you to use exposed fields from the package as keys for the map.

This means that you don't have to worry about messing or mispelling parameters, and also if you are designing this as a public API, you don't have to validate if what you are inserting is given correctly (like spelling).

# How does it work?

This works because the `expensesParam` type is private, as you cannot instantiate any instance of this type outside the current package, meaning that the only option available is to use the public constants that are defined inside `mypackage`.

Though you might think that by doing this you could enforce the same by doing
```go
type privateType string
type PublicType privateType

func MyFunc(t PublicType) { }
```
But this would not be the case, as you can just do `MyFunc(PublicType("got you"))`, since Go does not need to do the entire chain of conversions if the underlying type is still the same (`string` for this example).

What you should do instead is something like this
```go
type privateType string // can be any underlying type
type PublicType struct { Value privateType }
```
This will allow you to define your own set of constants that are the only valid options for calling the constrained function. ~~Unless you do some crazy and unsafe stuff to insert values inside the struct memory space~~. Keep in mind, that the only case that is valid to instantiate outside the package is the zero-value for `PublicType`, meaning that you can do just `PublicType{}`, and `Value` would be set to the zero-value (`""` for this example), so, either give meaning to it, or handle it appropriately.

Doing `type PublicType map[privateType]string` does not have that disadvantage, but still is as constrained as a map can be.

# An alternative approach to Enums

There are many ways in which you can define enums in Go, each option with its own dis/advantages, therefore I present to you another one with this approach.
