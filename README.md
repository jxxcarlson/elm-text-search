# Search

A library for searching lists of strings or of 
data with a function `f: Datum -> String`.

For example, running

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
[ ""foo yada", "hehe, baza baza!" ]
```

The query string `foo -bar | baz` is of the form 
`P | Q`.  It will match anything that matches `P` 
or `Q`. The term `P` is form `word1 -word2` It will
match anything that contains `word1` but not `word2`.
Similarly `word1 word2` matches anything that contains
`word1` and `word2`.

## Non-string data

Suppose that you want to query data of type `List Datum`.
You can do this if you have function like 
`digest : Datum -> String`.  For example, if

```text
type alias Datum = 
  {   title: String
    , tags : List String
    , ... other stuff ... 
   }          
```

Then `digest datum = String.join " " title::tags`
does the job — you can search using

```text
Search.withQueryString 
   digest 
   Search.NotCaseSensitive 
   "abc -xyz | pqr"
```