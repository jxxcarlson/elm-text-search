module TextSearch.Search exposing (matchWithQueryString, matchWithQueryTerm, withQueryString, Config(..))

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

Suppose that you want to query data of type `List Datum`.
You can do this if you have function like
`digest : Datum -> String`. For example, if

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

@docs matchWithQueryString, matchWithQueryTerm, withQueryString, Config

-}

import TextSearch.Parse exposing (QueryTerm(..), parse)


{-| -}
type Config
    = CaseSensitive
    | NotCaseSensitive


{-| -}
withQueryString : (datum -> String) -> Config -> String -> List datum -> List datum
withQueryString transformer config queryString dataList =
    case parse queryString of
        Ok term ->
            withTerm transformer config term dataList

        Err _ ->
            dataList


withTerm : (datum -> String) -> Config -> QueryTerm -> List datum -> List datum
withTerm transformer config term dataList =
    List.filter (matchWithQueryTerm transformer config term) dataList


{-| -}
matchWithQueryString : (datum -> String) -> Config -> String -> datum -> Bool
matchWithQueryString transformer config queryString datum =
    case parse queryString of
        Ok term ->
            matchWithQueryTerm transformer config term datum

        Err _ ->
            False


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
