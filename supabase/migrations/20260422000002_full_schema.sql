-- [SCHEMA] Full sprint schema — enums, all tables, RLS, indexes

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE currency_type AS ENUM ('scrolls', 'gems');
CREATE TYPE event_type    AS ENUM ('lava_quest', 'daily_challenge', 'special');
CREATE TYPE badge_type    AS ENUM ('hot', 'new', 'vip', 'none');

-- ============================================================
-- PROFILES — add energy columns
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN current_energy SMALLINT    NOT NULL DEFAULT 5,
  ADD COLUMN last_refill_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Energy columns are server-write only
REVOKE UPDATE (current_energy, last_refill_at) FROM authenticated;

-- ============================================================
-- SERIES
-- ============================================================

CREATE TABLE public.series (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title           TEXT        NOT NULL,
  description     TEXT,
  genre           TEXT,
  cover_url       TEXT,
  badge           badge_type  NOT NULL DEFAULT 'none',
  is_vip          BOOLEAN     NOT NULL DEFAULT FALSE,
  total_episodes  SMALLINT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.series ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Series are publicly readable"
  ON public.series FOR SELECT USING (TRUE);

-- ============================================================
-- EPISODES
-- ============================================================

CREATE TABLE public.episodes (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id        UUID        NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  episode_number   SMALLINT    NOT NULL,
  title            TEXT,
  description      TEXT,
  video_url        TEXT,
  thumbnail_url    TEXT,
  duration_seconds SMALLINT,
  is_free          BOOLEAN     NOT NULL DEFAULT FALSE,
  energy_cost      SMALLINT    NOT NULL DEFAULT 5,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (series_id, episode_number)
);

ALTER TABLE public.episodes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Episodes are publicly readable"
  ON public.episodes FOR SELECT USING (TRUE);

CREATE INDEX idx_episodes_series ON public.episodes(series_id);

-- ============================================================
-- COLLECTIBLES
-- ============================================================

CREATE TABLE public.collectibles (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id  UUID        NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  episode_id UUID        NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  image_url  TEXT,
  rarity     TEXT        NOT NULL DEFAULT 'common'
);

ALTER TABLE public.collectibles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Collectibles are publicly readable"
  ON public.collectibles FOR SELECT USING (TRUE);

CREATE INDEX idx_collectibles_episode ON public.collectibles(episode_id);

-- ============================================================
-- EPISODE CHOICES
-- ============================================================

CREATE TABLE public.episode_choices (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  episode_id    UUID NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  choice_key    TEXT NOT NULL,  -- 'A' or 'B'
  label         TEXT NOT NULL,
  collectible_id UUID REFERENCES public.collectibles(id),
  UNIQUE (episode_id, choice_key)
);

ALTER TABLE public.episode_choices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Episode choices are publicly readable"
  ON public.episode_choices FOR SELECT USING (TRUE);

CREATE INDEX idx_choices_episode ON public.episode_choices(episode_id);

-- ============================================================
-- ALBUMS
-- ============================================================

CREATE TABLE public.albums (
  id          UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id   UUID     NOT NULL REFERENCES public.series(id) ON DELETE CASCADE UNIQUE,
  name        TEXT     NOT NULL,
  total_cards SMALLINT NOT NULL
);

ALTER TABLE public.albums ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Albums are publicly readable"
  ON public.albums FOR SELECT USING (TRUE);

-- ============================================================
-- CHARACTERS
-- ============================================================

CREATE TABLE public.characters (
  id                  UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id           UUID     NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  name                TEXT     NOT NULL,
  avatar_url          TEXT,
  affinity_threshold_1 SMALLINT NOT NULL DEFAULT 10,
  affinity_threshold_2 SMALLINT NOT NULL DEFAULT 25
);

ALTER TABLE public.characters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Characters are publicly readable"
  ON public.characters FOR SELECT USING (TRUE);

CREATE INDEX idx_characters_series ON public.characters(series_id);

-- ============================================================
-- ENERGY LOG
-- ============================================================

CREATE TABLE public.energy_log (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  delta        SMALLINT    NOT NULL,
  balance_after SMALLINT   NOT NULL,
  reason       TEXT        NOT NULL,
  reference_id UUID,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.energy_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own energy log"
  ON public.energy_log FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_energy_log_user ON public.energy_log(user_id, created_at DESC);

-- ============================================================
-- CURRENCY LEDGER
-- ============================================================

CREATE TABLE public.currency_ledger (
  id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID          NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  currency_type    currency_type NOT NULL,
  delta            INTEGER       NOT NULL,
  balance_after    INTEGER       NOT NULL,
  reason           TEXT          NOT NULL,
  idempotency_key  TEXT          NOT NULL UNIQUE,
  reference_id     UUID,
  created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

ALTER TABLE public.currency_ledger ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own currency ledger"
  ON public.currency_ledger FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_currency_ledger_user ON public.currency_ledger(user_id, created_at DESC);
CREATE INDEX idx_currency_ledger_type ON public.currency_ledger(user_id, currency_type);

-- ============================================================
-- EPISODE UNLOCKS
-- ============================================================

CREATE TABLE public.episode_unlocks (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  episode_id       UUID        NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  energy_cost_paid SMALLINT    NOT NULL,
  unlocked_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, episode_id)
);

ALTER TABLE public.episode_unlocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own episode unlocks"
  ON public.episode_unlocks FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_episode_unlocks_user ON public.episode_unlocks(user_id);

-- ============================================================
-- USER EPISODE CHOICES
-- ============================================================

CREATE TABLE public.user_episode_choices (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  episode_id UUID        NOT NULL REFERENCES public.episodes(id) ON DELETE CASCADE,
  choice_id  UUID        NOT NULL REFERENCES public.episode_choices(id),
  chosen_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, episode_id)
);

ALTER TABLE public.user_episode_choices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own choices"
  ON public.user_episode_choices FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own choices"
  ON public.user_episode_choices FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_user_choices_user ON public.user_episode_choices(user_id);

-- ============================================================
-- USER COLLECTIBLES
-- ============================================================

CREATE TABLE public.user_collectibles (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  collectible_id   UUID        NOT NULL REFERENCES public.collectibles(id) ON DELETE CASCADE,
  source_choice_id UUID        REFERENCES public.user_episode_choices(id),
  earned_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, collectible_id)
);

ALTER TABLE public.user_collectibles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own collectibles"
  ON public.user_collectibles FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_user_collectibles_user ON public.user_collectibles(user_id);

-- ============================================================
-- CHARACTER AFFINITY
-- ============================================================

CREATE TABLE public.character_affinity (
  user_id          UUID     NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  character_id     UUID     NOT NULL REFERENCES public.characters(id) ON DELETE CASCADE,
  affinity_points  SMALLINT NOT NULL DEFAULT 0,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, character_id)
);

ALTER TABLE public.character_affinity ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own character affinity"
  ON public.character_affinity FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- EVENTS
-- ============================================================

CREATE TABLE public.events (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type  event_type  NOT NULL,
  title       TEXT        NOT NULL,
  description TEXT,
  starts_at   TIMESTAMPTZ NOT NULL,
  ends_at     TIMESTAMPTZ NOT NULL,
  is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
  config      JSONB       NOT NULL DEFAULT '{}'
);

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Events are publicly readable"
  ON public.events FOR SELECT USING (TRUE);

CREATE INDEX idx_events_active ON public.events(is_active, ends_at);

-- ============================================================
-- EVENT PARTICIPATION
-- ============================================================

CREATE TABLE public.event_participation (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  event_id       UUID        NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  progress       INTEGER     NOT NULL DEFAULT 0,
  completed      BOOLEAN     NOT NULL DEFAULT FALSE,
  reward_claimed BOOLEAN     NOT NULL DEFAULT FALSE,
  joined_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, event_id)
);

ALTER TABLE public.event_participation ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own event participation"
  ON public.event_participation FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can join events"
  ON public.event_participation FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_event_participation_user ON public.event_participation(user_id);

-- ============================================================
-- RACES (DRAMA SPRINT)
-- ============================================================

CREATE TABLE public.races (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  series_id  UUID        NOT NULL REFERENCES public.series(id) ON DELETE CASCADE,
  title      TEXT        NOT NULL,
  starts_at  TIMESTAMPTZ NOT NULL,
  ends_at    TIMESTAMPTZ NOT NULL,
  is_active  BOOLEAN     NOT NULL DEFAULT TRUE
);

ALTER TABLE public.races ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Races are publicly readable"
  ON public.races FOR SELECT USING (TRUE);

CREATE INDEX idx_races_active ON public.races(is_active, ends_at);

-- ============================================================
-- RACE PARTICIPANTS
-- ============================================================

CREATE TABLE public.race_participants (
  user_id          UUID     NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  race_id          UUID     NOT NULL REFERENCES public.races(id) ON DELETE CASCADE,
  episodes_watched SMALLINT NOT NULL DEFAULT 0,
  rank             SMALLINT,
  joined_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, race_id)
);

ALTER TABLE public.race_participants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Race participants are publicly readable"
  ON public.race_participants FOR SELECT USING (TRUE);
CREATE POLICY "Users can join races"
  ON public.race_participants FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_race_participants_race ON public.race_participants(race_id, episodes_watched DESC);

-- ============================================================
-- WATCH CLUBS
-- ============================================================

CREATE TABLE public.watch_clubs (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT        NOT NULL,
  owner_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  description  TEXT,
  member_count SMALLINT    NOT NULL DEFAULT 1,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.watch_clubs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Watch clubs are publicly readable"
  ON public.watch_clubs FOR SELECT USING (TRUE);
CREATE POLICY "Users can create watch clubs"
  ON public.watch_clubs FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- ============================================================
-- WATCH CLUB MEMBERS
-- ============================================================

CREATE TABLE public.watch_club_members (
  club_id   UUID        NOT NULL REFERENCES public.watch_clubs(id) ON DELETE CASCADE,
  user_id   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (club_id, user_id)
);

ALTER TABLE public.watch_club_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Club members are publicly readable"
  ON public.watch_club_members FOR SELECT USING (TRUE);
CREATE POLICY "Users can join clubs"
  ON public.watch_club_members FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- DAILY CHECK-INS
-- ============================================================

CREATE TABLE public.daily_checkins (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID    NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  checkin_date DATE    NOT NULL,
  day_number   SMALLINT NOT NULL,
  reward_coins INTEGER NOT NULL DEFAULT 0,
  reward_gems  SMALLINT NOT NULL DEFAULT 0,
  UNIQUE (user_id, checkin_date)
);

ALTER TABLE public.daily_checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own check-ins"
  ON public.daily_checkins FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_daily_checkins_user ON public.daily_checkins(user_id, checkin_date DESC);

-- ============================================================
-- QUESTS
-- ============================================================

CREATE TABLE public.quests (
  id           UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  title        TEXT     NOT NULL,
  description  TEXT,
  reward_coins INTEGER  NOT NULL DEFAULT 0,
  reward_xp    SMALLINT NOT NULL DEFAULT 0,
  target_count SMALLINT NOT NULL DEFAULT 1,
  quest_type   TEXT     NOT NULL,
  is_daily     BOOLEAN  NOT NULL DEFAULT FALSE
);

ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Quests are publicly readable"
  ON public.quests FOR SELECT USING (TRUE);

-- ============================================================
-- USER QUESTS
-- ============================================================

CREATE TABLE public.user_quests (
  user_id    UUID     NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  quest_id   UUID     NOT NULL REFERENCES public.quests(id) ON DELETE CASCADE,
  progress   SMALLINT NOT NULL DEFAULT 0,
  completed  BOOLEAN  NOT NULL DEFAULT FALSE,
  claimed    BOOLEAN  NOT NULL DEFAULT FALSE,
  reset_date DATE,
  PRIMARY KEY (user_id, quest_id)
);

ALTER TABLE public.user_quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own quests"
  ON public.user_quests FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_user_quests_user ON public.user_quests(user_id);

-- ============================================================
-- AD VIEWS
-- ============================================================

CREATE TABLE public.ad_views (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  viewed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reward_type   TEXT        NOT NULL,
  reward_amount SMALLINT    NOT NULL
);

ALTER TABLE public.ad_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own ad views"
  ON public.ad_views FOR SELECT USING (auth.uid() = user_id);

CREATE INDEX idx_ad_views_user_date ON public.ad_views(user_id, viewed_at DESC);
