module SearchTest exposing (suite)

--- (SearchConfig(..), mySearch)

import Expect
import Test exposing (..)
import TextSearch.Parse exposing (QueryTerm(..), parse)
import TextSearch.Search as Search


suite : Test
suite =
    describe "API"
        [ test "parser (conjuction with negative term)" <|
            \_ ->
                parse "foo -bar"
                    |> Expect.equal (Ok (Disjunction [ Conjunction [ Word "foo", NotWord "bar" ] ]))
        , test "parser (disjunction with negative term)" <|
            \_ ->
                parse "foo -bar | x y"
                    |> Expect.equal (Ok (Disjunction [ Conjunction [ Word "foo", NotWord "bar" ], Conjunction [ Word "x", Word "y" ] ]))
        , test "simple match (positive)" <|
            \_ ->
                Search.matchWithQueryString identity Search.NotCaseSensitive "bar" "foo bar"
                    |> Expect.equal True
        , test "simple match (negative)" <|
            \_ ->
                Search.matchWithQueryString identity Search.NotCaseSensitive "baz" "foo bar"
                    |> Expect.equal False
        , test "conjunctive match (positive)" <|
            \_ ->
                Search.matchWithQueryString identity Search.NotCaseSensitive "foo bar" "foo bar baz"
                    |> Expect.equal True
        , test "conjunctive match (negative)" <|
            \_ ->
                Search.matchWithQueryString identity Search.NotCaseSensitive "foo alpha" "foo bar baz"
                    |> Expect.equal False
        , test "conjunctive match with negation (positive)" <|
            \_ ->
                Search.matchWithQueryString identity Search.NotCaseSensitive "foo -fa" "foo bar baz"
                    |> Expect.equal True
        , test "conjunctive match with negation (negative)" <|
            \_ ->
                Search.matchWithQueryString identity Search.NotCaseSensitive "foo -bar" "foo bar baz"
                    |> Expect.equal False
        , test "simple search" <|
            \_ ->
                Search.withQueryString identity Search.NotCaseSensitive "abc" [ "abc def", "def xyz", "xyz abc  pqr" ]
                    |> Expect.equal [ "abc def", "xyz abc  pqr" ]
        , test "conjunctive search" <|
            \_ ->
                Search.withQueryString identity Search.NotCaseSensitive "abc xyz" [ "abc def", "def xyz", "xyz abc  pqr" ]
                    |> Expect.equal [ "xyz abc  pqr" ]
        , test "conjunctive search with negation" <|
            \_ ->
                Search.withQueryString identity Search.NotCaseSensitive "abc -xyz" [ "abc def", "def xyz", "xyz abc  pqr" ]
                    |> Expect.equal [ "abc def" ]
        , test "disjunctive search with negation" <|
            \_ ->
                Search.withQueryString identity Search.NotCaseSensitive "abc -xyz | pqr" [ "abc def", "def xyz", "xyz abc pqr" ]
                    |> Expect.equal [ "abc def", "xyz abc pqr" ]
        ]
