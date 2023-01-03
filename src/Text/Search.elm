module Text.Search exposing (Config(..), matchWithQueryStringToResult, withQueryStringToResult, matchWithQueryString, withQueryString)

{-|


## Basic usage

Let

    match =
        Search.withQueryString
            identity
            Search.NotCaseSensitive
            "foo -bar | baz"

Run `match` on the list

        [ "foo yada", "foo bar", "hehe, baza baza!" ]

It will return

        [ "foo yada", "hehe, baza baza!" ]

The query string `foo -bar | baz` is of the form
`P | Q`. It will match anything that matches `P`
or `Q`. The term `P` is form `word1 -word2` It will
match anything that contains `word1` but not `word2`.
Similarly, `word1 word2` matches anything that contains
`word1` and `word2`.


## Non-string data

Suppose that you want to query data of type `List a`.
You can do this if you have function like
`digest : a -> String`. For example, if

    type alias Datum =
      {   title: String
        , tags : List String
        , ... other stuff ...
       }

Then `digest datum = String.join " " title::tags`
does the job — you can search using

    Search.withQueryString
        digest
        Search.NotCaseSensitive
        "foo -bar | baz"

Below we describe the types and functions exported from this module.

@docs Config, matchWithQueryStringToResult, withQueryStringToResult, matchWithQueryString, withQueryString

-}

import Text.Parse exposing (QueryTerm(..), parse)


{-| -}
type Config
    = CaseSensitive
    | NotCaseSensitive


{-| Filter the data list using the query. If the query is ill-formed, return the empty list.
-}
withQueryString : (datum -> String) -> Config -> String -> List datum -> List datum
withQueryString transformer config queryString dataList =
    case parse queryString of
        Ok term ->
            withTerm transformer config term dataList

        Err _ ->
            []


{-| Filter the data list using the query.
If the query string is well-formed,
`Ok filteredList` is returned. If it
is ill-formed, `Err errorString`
is returned. At the moment, the
error string reads 'ill-formed query'.
-}
withQueryStringToResult : (datum -> String) -> Config -> String -> List datum -> Result String (List datum)
withQueryStringToResult transformer config queryString dataList =
    case parse queryString of
        Ok term ->
            Ok (withTerm transformer config term dataList)

        Err errorMessage ->
            Err errorMessage


withTerm : (datum -> String) -> Config -> QueryTerm -> List datum -> List datum
withTerm transformer config term dataList =
    List.filter (matchWithQueryTerm transformer config term) dataList


{-| If the query string is well-formed, `Ok True/False` is returned depending
on whether the query string matches the datum. If the query string
is ill-formed, `False` is returned.
-}
matchWithQueryString : (datum -> String) -> Config -> String -> datum -> Bool
matchWithQueryString transformer config queryString datum =
    case parse queryString of
        Ok term ->
            matchWithQueryTerm transformer config term datum

        Err _ ->
            False


{-| If the query string is well-formed, `Ok True/False` is returned,
the result depending
on whether the query string matches datum.
If it is ill-formed, `Err errorString` is returned. At the moment, the
error string reads 'ill-formed query'.
-}
matchWithQueryStringToResult : (datum -> String) -> Config -> String -> datum -> Result String Bool
matchWithQueryStringToResult transformer config queryString datum =
    case parse queryString of
        Ok term ->
            Ok (matchWithQueryTerm transformer config term datum)

        Err errorMessage ->
            Err errorMessage


{-| -}
matchWithQueryTerm : (datum -> String) -> Config -> QueryTerm -> datum -> Bool
matchWithQueryTerm transformer config term datum =
    case term of
        Word w ->
            case config of
                CaseSensitive ->
                    String.contains w (transformer datum)

                NotCaseSensitive ->
                    String.contains (String.toLower w) (String.toLower (transformer datum))

        NotWord w ->
            case config of
                CaseSensitive ->
                    not (String.contains w (transformer datum))

                NotCaseSensitive ->
                    not (String.contains (String.toLower w) (String.toLower (transformer datum)))

        Conjunction terms ->
            List.foldl (\term_ acc -> matchWithQueryTerm transformer config term_ datum && acc) True terms

        Disjunction terms ->
            List.foldl (\term_ acc -> matchWithQueryTerm transformer config term_ datum || acc) False terms
