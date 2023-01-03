# Elm Text-Search

`Text.Search`  and `Text.Parse` provide functions
for searching lists of strings or lists of
data endowed with a function `f: a -> String`.  Queries
are strings which 
look like `foo`, `-foo`, `foo bar`, `foo -bar`, `foo | bar`, 
etc.  A query with `foo` will match strings containing
`foo` while a query with `-foo` will match strings not
containing `foo`.  A search with `foo bar` is a conjunctive 
search: it returns strings containing both `foo` and `bar`.
Naturally enough, a search with `foo -bar` returns strings
containing `foo` but not `bar`.  Finally, `foo | bar`
provides for disjunctive searches: strings containing
`foo` or `bar` will be returned.  

Any query in so-called
disjunctive normal form is accepted.  Such a query
is a disjunction of elementary conjunctions, that is,
conjunctions of basic terms such as `WORD` and 
`-WORD`.

## Example

Running

```elm
Search.withQueryString 
   identity 
   Search.NotCaseSensitive 
   "foo -bar | baz"
```

on the list

```elm
[ "foo yada", "foo bar", "hehe, baza baza!" ]
```

returns the list

```elm
[ "foo yada", "hehe, baza baza!" ]
```


## Parse errors

It can happen that the query string is ill-formed, e.g., 
`foo && bar`.  The functions `matchWithQueryStringToResult`
and `withQueryStringToResult` return `Result String Bool`
and `Result String (List a)`, respectively and can be
used to take action when the query string is ill-formed.
At the moment the error message is primitive: "ill-formed query"
in all cases.

The companion functions `matchWithQueryString`
and `withQueryString` are easy to use but simply
return `False` and the empty list, respectively,
when the query string is ill-formed.  

## Spaces

Search terms with spaces are allowed: just surround
the term with single quotes.  The term
`'foo bar'` will match "foo bar" but neither "bar foo"
nor "foo baz bar".


## Non-string data

Suppose that you want to query data of type `List a`.
You can do this if you have function like 
`digest : a -> String`.  For example, if

```elm
type alias Datum = 
  {   title: String
    , tags : List String
    , ... other stuff ... 
   }          
```

Then

```elm
digest datum = String.join " " title::tags
```

does the job — you can search using

```elm
Search.withQueryString 
   digest 
   Search.NotCaseSensitive 
   "foo -bar | baz"
```