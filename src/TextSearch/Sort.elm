module TextSearch.Sort exposing (sort, SortParam(..), Direction(..))

{-|

@docs sort, SortParam, Direction

-}

import Random
import Random.List


{-| -}
type SortParam
    = Random Random.Seed


{-| -}
sort : (a -> comparable) -> SortParam -> List a -> List a
sort transform param dataList =
    case param of
        Random seed ->
            Random.step (Random.List.shuffle dataList) seed |> Tuple.first
