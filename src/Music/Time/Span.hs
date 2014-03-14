
{-# LANGUAGE ConstraintKinds            #-}
{-# LANGUAGE DeriveFoldable             #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE ViewPatterns               #-}

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
-- Provides time spans.
--
-------------------------------------------------------------------------------------

module Music.Time.Span (
        Span,
        -- inSpan,

        -- ** Constructing spans
        (<->),
        (>->),
        era,

        -- ** Deconstructing spans
        -- _range,
        -- _delta,
        range,
        delta,
        -- mapRange,
        -- mapDelta,

        -- ** Span as transformation
        sunit,
        sapp,
        sunder,
        sinvert,
  ) where

import           Control.Arrow
import           Control.Lens
import           Data.AffineSpace
import           Data.AffineSpace.Point
import           Data.Semigroup
import           Data.VectorSpace

import           Music.Time.Delayable
import           Music.Time.Onset
import           Music.Time.Reverse
import           Music.Time.Stretchable
import           Music.Time.Time

-- |
-- A 'Span' represents two points in time @u@ and @v@ where @t <= u@ or, equivalently,
-- a time @t@ and a duration @d@ where @d >= 0@.
--
-- A third way of looking at 'Span' is that it represents a time transformation where
-- onset is translation and duration is scaling.
--
newtype Span = Span (Time, Duration)
    deriving (Eq, Ord, Show)

-- normalizeSpan :: Span -> Span
-- normalizeSpan (Span (t,d))
    --  | d >= 0  =  t <-> (t .+^ d)
    --  | d <  0  =  (t .+^ d) <-> t

{-
    "Applying a transformation t to a Located a results in the transformation being
    applied to the location, and the linear portion of t being applied to the value of
    type a (i.e. it is not translated)."

        -- Diagrams Haddocks
-}
instance Delayable Span where
    delay n = delta %~ first (delay n)

instance Stretchable Span where
    stretch n = delta %~ (stretch n *** stretch n)


instance HasOnset Span where
    onset = fst . _range

instance HasOffset Span where
    offset = snd . _range

instance HasDuration Span where
    duration = snd . _delta

instance Semigroup Span where
    -- Span (t1, d1) <> Span (t2, d2) = Span (t1 `delayTime` (d1 `stretch` t2), d1 `stretch` d2)
    (<>) = sapp


instance Monoid Span where
    mempty  = start <-> stop
    mappend = (<>)

inSpan f = Span . f . _delta

-- |
-- The default span, i.e. 'start' '<->' 'stop'.
--
sunit :: Span
sunit = mempty

-- | @t \<-\> u@ represents the span between @t@ and @u@.
(<->) :: Time -> Time -> Span
(<->) t u = t >-> (u .-. t)

-- | @t >-> d@ represents the span between @t@ and @t .+^ d@.
(>->) :: Time -> Duration -> Span
t >-> d = Span (t,d)
    --  | d > 0     = Span (t,d)
    --  | otherwise = error "Invalid span"

-- | Get the era (onset to offset) of a given value.
era :: (HasOnset a, HasOffset a) => a -> Span
era x = onset x <-> offset x

_delta :: Span -> (Time, Duration)
_delta (Span x) = x

_range :: Span -> (Time, Time)
_range x = let (t, d) = _delta x
    in (t, t .+^ d)

-- |
-- View a span as onset and offset.
--
-- Typically used with the @ViewPatterns@ extension, as in
--
-- > foo (view range -> (u,v)) = ...
--
range :: Iso' Span (Time, Time)
range = iso _range $ uncurry (<->)

-- |
-- View a span as a time and duration.
--
-- Typically used with the @ViewPatterns@ extension, as in
--
-- > foo (view delta -> (t,d)) = ...
--
delta :: Iso' Span (Time, Duration)
delta = iso _delta $ uncurry (>->)

-- | Apply a span transformation.
sapp :: (Delayable a, Stretchable a) => Span -> a -> a
sapp (view delta -> (t,d)) = delayTime t . stretch d

-- | Apply a function under a span transformation.
sunder :: (Delayable a, Stretchable a, Delayable b, Stretchable b) => Span -> (a -> b) -> a -> b
-- sunder s f = sapp (sinvert s) . f . sapp s

sunder s f = sappInv s . f . sapp s
sappInv (view delta -> (t,d)) = stretch (recip d) . delayTime (mirror t)

-- | The inversion of a span.
--
-- > sinvert (sinvert s) = s
-- > sapp (sinvert s) . sapp s = id
--
sinvert :: Span -> Span
sinvert (Span (t,d)) = Span (mirror t, recip d)

-- TODO add "individual scaling" component, i.e. scale just duration not both time and duration
-- Useful for implementing separation in articulation etc

deriving instance Delayable a => Delayable (NoStretch a)
deriving instance HasOnset a => HasOnset (NoStretch a)
deriving instance HasOffset a => HasOffset (NoStretch a)
deriving instance HasDuration a => HasDuration (NoStretch a)

deriving instance Stretchable a => Stretchable (NoDelay a)
deriving instance HasOnset a => HasOnset (NoDelay a)
deriving instance HasOffset a => HasOffset (NoDelay a)
deriving instance HasDuration a => HasDuration (NoDelay a)


