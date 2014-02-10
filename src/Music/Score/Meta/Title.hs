
{-# LANGUAGE 
    ScopedTypeVariables, 
    GeneralizedNewtypeDeriving,
    DeriveFunctor, 
    DeriveFoldable, 
    DeriveTraversable,
    DeriveDataTypeable, 
    ConstraintKinds,
    FlexibleContexts, 
    GADTs, 
    ViewPatterns,
    TypeFamilies,
    MultiParamTypeClasses, 
    FlexibleInstances #-}

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
-------------------------------------------------------------------------------------

module Music.Score.Meta.Title (

        -- * Title type
        Title,   
        
        -- ** Creating and modifying
        -- titleFromString,
        denoteTitle,
        getTitle,
        getTitleAt,    

        -- * Adding titles to scores
        title,
        titleDuring,
        subtitle,
        subtitleDuring,        
        subsubtitle,
        subsubtitleDuring,        
        
        -- * Extracting titles
        withTitle,        
  ) where

import Control.Arrow
import Control.Monad.Plus       
import Data.Void
import Data.Maybe
import Data.Semigroup
import Data.Monoid.WithSemigroup
import Data.Typeable
import Data.String
import Data.Set (Set)
import Data.Map (Map)
import Data.Foldable (Foldable)
import Data.Traversable (Traversable)
import qualified Data.Foldable as F
import qualified Data.Traversable as T
import qualified Data.List as List
import qualified Data.Set as Set
import qualified Data.Map as Map

import Music.Time
import Music.Time.Reactive
import Music.Score.Note
import Music.Score.Voice
import Music.Score.Part
import Music.Score.Pitch
import Music.Score.Meta
import Music.Score.Score
import Music.Score.Combinators
import Music.Score.Util
import Music.Pitch.Literal

-- |
-- A title is a sequence of 'String' values, representing the name of a work or part of a work.
-- An arbitrary depth of title sections can be used.
--
-- Title is an instance of 'IsString' and can be used with the 'OverloadedStrings' extension as
-- follows:
--
-- > title  "Le Nozze di Figaro"
-- >
-- > subtitle "Atto primo" 
-- > subsubtitle "Scena I"
-- > subsubtitle "Scena II"
-- > ...
-- >
-- > subtitle "Atto secundo" 
-- > ...
--
newtype Title = Title (Int -> Option (Last String))
    deriving (Typeable, Monoid, Semigroup)

instance IsString Title where
    fromString x = Title $ \n -> if n == 0 then Option (Just (Last x)) else Option Nothing

instance Show Title where
    show = List.intercalate " " . getTitle

-- | Create a title from a string. See also 'fromString'.
titleFromString :: String -> Title
titleFromString = fromString

-- | Denote a title to a lower level, i.e title becomes subtitle, subtitle becomes subsubtitle etc.
denoteTitle :: Title -> Title
denoteTitle (Title t) = Title (t . subtract 1)

-- | Extract the title as a descending list of title levels (i.e. title, subtitle, subsubtitle...).
getTitle :: Title -> [String]
getTitle t = untilFail . fmap (getTitleAt t) $ [0..]
    where
        untilFail = fmap fromJust . takeWhile isJust

-- | Extract the title of the given level. Semantic function.
getTitleAt :: Title -> Int -> Maybe String
getTitleAt (Title t) n = fmap getLast . getOption . t $ n

-- | Set title of the given score.
title :: (HasMeta a, HasPart' a, HasOnset a, HasOffset a) => Title -> a -> a
title t x = titleDuring (era x) t x

-- | Set title of the given part of a score.
titleDuring :: (HasMeta a, HasPart' a) => Span -> Title -> a -> a
titleDuring s t = addGlobalMetaNote (s =: t)

-- | Set subtitle of the given score.
subtitle :: (HasMeta a, HasPart' a, HasOnset a, HasOffset a) => Title -> a -> a
subtitle t x = subtitleDuring (era x) t x

-- | Set subtitle of the given part of a score.
subtitleDuring :: (HasMeta a, HasPart' a) => Span -> Title -> a -> a
subtitleDuring s t = addGlobalMetaNote (s =: denoteTitle t)

-- | Set subsubtitle of the given score.
subsubtitle :: (HasMeta a, HasPart' a, HasOnset a, HasOffset a) => Title -> a -> a
subsubtitle t x = subsubtitleDuring (era x) t x

-- | Set subsubtitle of the given part of a score.
subsubtitleDuring :: (HasMeta a, HasPart' a) => Span -> Title -> a -> a
subsubtitleDuring s t = addGlobalMetaNote (s =: denoteTitle (denoteTitle t))

-- | Extract the title in from the given score.
withTitle :: (Title -> Score a -> Score a) -> Score a -> Score a
withTitle = withGlobalMetaAtStart

