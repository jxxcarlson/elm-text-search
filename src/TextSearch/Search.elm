module TextSearch.Search exposing (matchWithQueryString, matchWithQueryTerm, withQueryString, Config(..))

{-| See the README for examples.

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
