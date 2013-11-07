
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

-------------------------------------------------------------------------------------
-- |
-- Copyright   : (c) Hans Hoglund 2012
--
-- License     : BSD-style
--
-- Maintainer  : hans@hanshoglund.se
-- Stability   : experimental
-- Portability : non-portable (TF,GNTD)
--
-- Provides reversible values.
--
-------------------------------------------------------------------------------------

module Music.Time.Reverse (
        -- * Reversible class
        Reversible(..),
       
        -- ** Utility
        NoRev(..),
        WithRev(..),
        withRev,
        fromWithRev,
  ) where

import Data.Ratio
import Data.Semigroup
import Data.VectorSpace
import Data.AffineSpace
import Data.AffineSpace.Point
import Data.Set (Set)
import Data.Map (Map)
import qualified Data.Map as Map
import qualified Data.Set as Set

import Music.Time.Relative
import Music.Time.Time
import Music.Time.Onset
import Music.Time.Juxtapose -- for Transformable

-- |
-- Reversible values.
--
-- For instances of 'Reversible' and 'HasOnset', the following laws should hold:
--
-- > onset a    = onset (rev a)
-- > duration a = duration (rev a)
--
-- For structural types, 'rev' is applied recursively, hence the constraint on
-- the 'Score' instance. 'rev' is id by default, so for a trivial type @T@ it
-- suffices to write
--
-- > instance Reversible T 
--
-- For instances 'U' of 'HasOnset' and 'Transformable', a suitable instance
-- is
--
-- > instance Reversible T where
-- >     rev = withSameOnset (stretch (-1))
--
--
class Reversible a where

    -- |
    -- Reverse a value.
    --
    -- Reverse is an involution, meaning that:
    --
    -- > rev (rev a) = a
    --
    rev :: a -> a
    rev = id

-- instance Reversible Time where
    -- rev t = mirror t

instance Reversible Double
instance Reversible Float
instance Reversible Int
instance Reversible Integer
instance Reversible ()
instance Reversible (Ratio a)

instance Reversible a => Reversible [a] where
    rev = fmap rev

instance (Ord a, Reversible a) => Reversible (Set a) where
    rev = Set.map rev

instance Reversible a => Reversible (Map k a) where
    rev = fmap rev

newtype NoRev a = NoRev { getNoRev :: a }
    deriving (Eq, Ord, Enum, Show, Semigroup, Monoid)

instance Reversible (NoRev a) where
    rev = id



newtype WithRev a = WithRev (a,a)
    deriving (Eq, Ord, Semigroup, Monoid)

withRev :: Reversible a => a -> WithRev a
withRev x = WithRev (rev x, x)

fromWithRev :: Reversible a => WithRev a -> a
fromWithRev (WithRev (_,x)) = x

instance Reversible a => Reversible (WithRev a) where
    rev (WithRev (r,x)) = WithRev (x,r)



