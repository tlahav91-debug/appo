-- ============================================================
-- Seed data for AI Drama Game
-- Run after migrations. Safe to re-run (uses INSERT ... ON CONFLICT DO NOTHING).
-- ============================================================

-- ============================================================
-- SERIES (8 placeholder drama series)
-- ============================================================

INSERT INTO public.series (id, title, description, genre, badge, is_vip, total_episodes) VALUES
  ('00000000-0000-0000-0000-000000000001', 'The Heiress Returns',      'A billionaire heiress reclaims what is hers.',              'Romance', 'hot',  FALSE, 5),
  ('00000000-0000-0000-0000-000000000002', 'Billionaire''s Secret Wife','She married him in secret — now everyone wants to know.',   'Romance', 'new',  FALSE, 5),
  ('00000000-0000-0000-0000-000000000003', 'CEO''s Fake Fiancée',       'One fake engagement. Two real hearts.',                     'Romance', 'none', FALSE, 5),
  ('00000000-0000-0000-0000-000000000004', 'Married by Mistake',        'A contract marriage that became something more.',           'Romance', 'none', FALSE, 5),
  ('00000000-0000-0000-0000-000000000005', 'My Boss''s Obsession',      'He promised to stay professional. He lied.',                'Romance', 'none', TRUE,  5),
  ('00000000-0000-0000-0000-000000000006', 'The Cold Prince''s Bride',  'An ancient kingdom, a forbidden love, an iron will.',       'Historical','none',FALSE, 5),
  ('00000000-0000-0000-0000-000000000007', 'Kidnapped by Mafia Boss',   'She saw something she shouldn''t. Now she can''t leave.',   'Thriller','hot',  FALSE, 5),
  ('00000000-0000-0000-0000-000000000008', 'Love After Revenge',        'Revenge was the plan. Love was never part of it.',          'Thriller','none', FALSE, 5)
ON CONFLICT DO NOTHING;

-- ============================================================
-- ALBUMS (1 per series)
-- ============================================================

INSERT INTO public.albums (id, series_id, name, total_cards) VALUES
  ('00000000-0001-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Heiress Returns Album',       10),
  ('00000000-0001-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'Secret Wife Album',           10),
  ('00000000-0001-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'Fake Fiancée Album',          10),
  ('00000000-0001-0000-0000-000000000004', '00000000-0000-0000-0000-000000000004', 'Married by Mistake Album',    10),
  ('00000000-0001-0000-0000-000000000005', '00000000-0000-0000-0000-000000000005', 'Boss''s Obsession Album',     10),
  ('00000000-0001-0000-0000-000000000006', '00000000-0000-0000-0000-000000000006', 'Cold Prince Album',           10),
  ('00000000-0001-0000-0000-000000000007', '00000000-0000-0000-0000-000000000007', 'Mafia Boss Album',            10),
  ('00000000-0001-0000-0000-000000000008', '00000000-0000-0000-0000-000000000008', 'Love After Revenge Album',    10)
ON CONFLICT DO NOTHING;

-- ============================================================
-- EPISODES (5 per series: ep 1-2 free, ep 3-5 paid)
-- Series 1: The Heiress Returns
-- ============================================================

INSERT INTO public.episodes (id, series_id, episode_number, title, is_free, energy_cost) VALUES
  ('00000000-0002-0001-0000-000000000001','00000000-0000-0000-0000-000000000001',1,'The Return',          TRUE, 0),
  ('00000000-0002-0001-0000-000000000002','00000000-0000-0000-0000-000000000001',2,'Old Enemies',         TRUE, 0),
  ('00000000-0002-0001-0000-000000000003','00000000-0000-0000-0000-000000000001',3,'The Confrontation',   FALSE,5),
  ('00000000-0002-0001-0000-000000000004','00000000-0000-0000-0000-000000000001',4,'Unexpected Alliance', FALSE,5),
  ('00000000-0002-0001-0000-000000000005','00000000-0000-0000-0000-000000000001',5,'The Reckoning',       FALSE,5),
-- Series 2: Billionaire's Secret Wife
  ('00000000-0002-0002-0000-000000000001','00000000-0000-0000-0000-000000000002',1,'The Secret',          TRUE, 0),
  ('00000000-0002-0002-0000-000000000002','00000000-0000-0000-0000-000000000002',2,'Exposed',             TRUE, 0),
  ('00000000-0002-0002-0000-000000000003','00000000-0000-0000-0000-000000000002',3,'His Discovery',       FALSE,5),
  ('00000000-0002-0002-0000-000000000004','00000000-0000-0000-0000-000000000002',4,'The Decision',        FALSE,5),
  ('00000000-0002-0002-0000-000000000005','00000000-0000-0000-0000-000000000002',5,'Together at Last',    FALSE,5),
-- Series 3: CEO's Fake Fiancée
  ('00000000-0002-0003-0000-000000000001','00000000-0000-0000-0000-000000000003',1,'The Proposal',        TRUE, 0),
  ('00000000-0002-0003-0000-000000000002','00000000-0000-0000-0000-000000000003',2,'Playing the Part',    TRUE, 0),
  ('00000000-0002-0003-0000-000000000003','00000000-0000-0000-0000-000000000003',3,'Feelings Complicate', FALSE,5),
  ('00000000-0002-0003-0000-000000000004','00000000-0000-0000-0000-000000000003',4,'The Real Deal',       FALSE,5),
  ('00000000-0002-0003-0000-000000000005','00000000-0000-0000-0000-000000000003',5,'No More Pretending',  FALSE,5),
-- Series 4: Married by Mistake
  ('00000000-0002-0004-0000-000000000001','00000000-0000-0000-0000-000000000004',1,'The Wrong Name',      TRUE, 0),
  ('00000000-0002-0004-0000-000000000002','00000000-0000-0000-0000-000000000004',2,'Stuck Together',      TRUE, 0),
  ('00000000-0002-0004-0000-000000000003','00000000-0000-0000-0000-000000000004',3,'Learning to Live',    FALSE,5),
  ('00000000-0002-0004-0000-000000000004','00000000-0000-0000-0000-000000000004',4,'The Annulment',       FALSE,5),
  ('00000000-0002-0004-0000-000000000005','00000000-0000-0000-0000-000000000004',5,'I Choose You',        FALSE,5),
-- Series 5: My Boss's Obsession
  ('00000000-0002-0005-0000-000000000001','00000000-0000-0000-0000-000000000005',1,'First Day',           TRUE, 0),
  ('00000000-0002-0005-0000-000000000002','00000000-0000-0000-0000-000000000005',2,'Off-Limits',          TRUE, 0),
  ('00000000-0002-0005-0000-000000000003','00000000-0000-0000-0000-000000000005',3,'Breaking the Rules',  FALSE,5),
  ('00000000-0002-0005-0000-000000000004','00000000-0000-0000-0000-000000000005',4,'The Ultimatum',       FALSE,5),
  ('00000000-0002-0005-0000-000000000005','00000000-0000-0000-0000-000000000005',5,'His and Hers',        FALSE,5),
-- Series 6: The Cold Prince's Bride
  ('00000000-0002-0006-0000-000000000001','00000000-0000-0000-0000-000000000006',1,'The Decree',          TRUE, 0),
  ('00000000-0002-0006-0000-000000000002','00000000-0000-0000-0000-000000000006',2,'The Palace',          TRUE, 0),
  ('00000000-0002-0006-0000-000000000003','00000000-0000-0000-0000-000000000006',3,'Forbidden Glances',   FALSE,5),
  ('00000000-0002-0006-0000-000000000004','00000000-0000-0000-0000-000000000006',4,'War and Hearts',      FALSE,5),
  ('00000000-0002-0006-0000-000000000005','00000000-0000-0000-0000-000000000006',5,'The Thaw',            FALSE,5),
-- Series 7: Kidnapped by Mafia Boss
  ('00000000-0002-0007-0000-000000000001','00000000-0000-0000-0000-000000000007',1,'Wrong Place',         TRUE, 0),
  ('00000000-0002-0007-0000-000000000002','00000000-0000-0000-0000-000000000007',2,'No Escape',           TRUE, 0),
  ('00000000-0002-0007-0000-000000000003','00000000-0000-0000-0000-000000000007',3,'Stockholm',           FALSE,5),
  ('00000000-0002-0007-0000-000000000004','00000000-0000-0000-0000-000000000007',4,'The Truth',           FALSE,5),
  ('00000000-0002-0007-0000-000000000005','00000000-0000-0000-0000-000000000007',5,'Free to Stay',        FALSE,5),
-- Series 8: Love After Revenge
  ('00000000-0002-0008-0000-000000000001','00000000-0000-0000-0000-000000000008',1,'The Plan',            TRUE, 0),
  ('00000000-0002-0008-0000-000000000002','00000000-0000-0000-0000-000000000008',2,'Getting Close',       TRUE, 0),
  ('00000000-0002-0008-0000-000000000003','00000000-0000-0000-0000-000000000008',3,'Complications',       FALSE,5),
  ('00000000-0002-0008-0000-000000000004','00000000-0000-0000-0000-000000000008',4,'Change of Heart',     FALSE,5),
  ('00000000-0002-0008-0000-000000000005','00000000-0000-0000-0000-000000000008',5,'Forgiveness',         FALSE,5)
ON CONFLICT DO NOTHING;

-- ============================================================
-- COLLECTIBLES (2 per episode: choice A card, choice B card)
-- Only seeding Series 1 in full for brevity; pattern repeats for all 8.
-- Using a DO block to generate all 80 collectibles programmatically.
-- ============================================================

DO $$
DECLARE
  s_ids UUID[] := ARRAY[
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000004',
    '00000000-0000-0000-0000-000000000005',
    '00000000-0000-0000-0000-000000000006',
    '00000000-0000-0000-0000-000000000007',
    '00000000-0000-0000-0000-000000000008'
  ];
  ep_id UUID;
  s_idx INT;
  ep_num INT;
  choice TEXT;
BEGIN
  FOR s_idx IN 1..8 LOOP
    FOR ep_num IN 1..5 LOOP
      -- Get episode id using the deterministic UUIDs we seeded above
      ep_id := ('00000000-0002-000' || s_idx || '-0000-00000000000' || ep_num)::UUID;
      FOR choice IN SELECT unnest(ARRAY['A','B']) LOOP
        INSERT INTO public.collectibles (series_id, episode_id, name, rarity)
        VALUES (
          s_ids[s_idx],
          ep_id,
          'Ep' || ep_num || ' Choice ' || choice || ' Card',
          CASE WHEN ep_num >= 4 THEN 'rare' ELSE 'common' END
        )
        ON CONFLICT DO NOTHING;
      END LOOP;
    END LOOP;
  END LOOP;
END;
$$;

-- ============================================================
-- EPISODE CHOICES (2 per episode, linked to collectibles)
-- Seeding for all episodes using a DO block
-- ============================================================

DO $$
DECLARE
  s_idx INT;
  ep_num INT;
  ep_id UUID;
  coll_a UUID;
  coll_b UUID;
BEGIN
  FOR s_idx IN 1..8 LOOP
    FOR ep_num IN 1..5 LOOP
      ep_id := ('00000000-0002-000' || s_idx || '-0000-00000000000' || ep_num)::UUID;

      SELECT id INTO coll_a FROM public.collectibles
        WHERE episode_id = ep_id AND name LIKE '%Choice A%' LIMIT 1;
      SELECT id INTO coll_b FROM public.collectibles
        WHERE episode_id = ep_id AND name LIKE '%Choice B%' LIMIT 1;

      INSERT INTO public.episode_choices (episode_id, choice_key, label, collectible_id)
      VALUES
        (ep_id, 'A', 'Stand your ground',  coll_a),
        (ep_id, 'B', 'Take the safe path', coll_b)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END LOOP;
END;
$$;

-- ============================================================
-- CHARACTERS (2 per series)
-- ============================================================

INSERT INTO public.characters (id, series_id, name, affinity_threshold_1, affinity_threshold_2) VALUES
  ('00000000-0003-0001-0000-000000000001','00000000-0000-0000-0000-000000000001','Ethan Cross',    10,25),
  ('00000000-0003-0001-0000-000000000002','00000000-0000-0000-0000-000000000001','Sofia Vance',    10,25),
  ('00000000-0003-0002-0000-000000000001','00000000-0000-0000-0000-000000000002','Lucas Hart',     10,25),
  ('00000000-0003-0002-0000-000000000002','00000000-0000-0000-0000-000000000002','Mia Sinclair',   10,25),
  ('00000000-0003-0003-0000-000000000001','00000000-0000-0000-0000-000000000003','Nathan Cole',    10,25),
  ('00000000-0003-0003-0000-000000000002','00000000-0000-0000-0000-000000000003','Aria Stone',     10,25),
  ('00000000-0003-0004-0000-000000000001','00000000-0000-0000-0000-000000000004','Damien Rowe',    10,25),
  ('00000000-0003-0004-0000-000000000002','00000000-0000-0000-0000-000000000004','Clara Banks',    10,25),
  ('00000000-0003-0005-0000-000000000001','00000000-0000-0000-0000-000000000005','Victor Hale',    10,25),
  ('00000000-0003-0005-0000-000000000002','00000000-0000-0000-0000-000000000005','Zoe Mercer',     10,25),
  ('00000000-0003-0006-0000-000000000001','00000000-0000-0000-0000-000000000006','Prince Kaelan',  10,25),
  ('00000000-0003-0006-0000-000000000002','00000000-0000-0000-0000-000000000006','Lady Iselle',    10,25),
  ('00000000-0003-0007-0000-000000000001','00000000-0000-0000-0000-000000000007','Marco Vitale',   10,25),
  ('00000000-0003-0007-0000-000000000002','00000000-0000-0000-0000-000000000007','Lena Pierce',    10,25),
  ('00000000-0003-0008-0000-000000000001','00000000-0000-0000-0000-000000000008','Ryder Quinn',    10,25),
  ('00000000-0003-0008-0000-000000000002','00000000-0000-0000-0000-000000000008','Nora Ellis',     10,25)
ON CONFLICT DO NOTHING;

-- ============================================================
-- EVENTS (1 live lava quest)
-- ============================================================

INSERT INTO public.events (id, event_type, title, description, starts_at, ends_at, is_active) VALUES
  (
    '00000000-0004-0000-0000-000000000001',
    'lava_quest',
    'Lava Quest: Hearts on Fire',
    'Watch 10 episodes this week to claim exclusive rewards.',
    NOW(),
    NOW() + INTERVAL '7 days',
    TRUE
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- RACES (1 open Drama Sprint for The Heiress Returns)
-- ============================================================

INSERT INTO public.races (id, series_id, title, starts_at, ends_at, is_active) VALUES
  (
    '00000000-0005-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'Drama Sprint: Heiress Returns',
    NOW(),
    NOW() + INTERVAL '14 days',
    TRUE
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- QUESTS (3 starter quests)
-- ============================================================

INSERT INTO public.quests (id, title, description, reward_coins, reward_xp, target_count, quest_type, is_daily) VALUES
  (
    '00000000-0006-0000-0000-000000000001',
    'First Watch',
    'Watch your first episode.',
    100, 20, 1, 'watch_episodes', FALSE
  ),
  (
    '00000000-0006-0000-0000-000000000002',
    'Decision Maker',
    'Make 3 story choices.',
    150, 30, 3, 'make_choices', FALSE
  ),
  (
    '00000000-0006-0000-0000-000000000003',
    'Coin Collector',
    'Earn 100 coins.',
    50, 10, 100, 'earn_coins', FALSE
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- VERIFY (uncomment to check counts after seeding)
-- ============================================================
-- SELECT 'series' AS tbl, COUNT(*) FROM public.series
-- UNION ALL SELECT 'episodes',     COUNT(*) FROM public.episodes
-- UNION ALL SELECT 'collectibles',  COUNT(*) FROM public.collectibles
-- UNION ALL SELECT 'characters',    COUNT(*) FROM public.characters
-- UNION ALL SELECT 'events',        COUNT(*) FROM public.events
-- UNION ALL SELECT 'races',         COUNT(*) FROM public.races
-- UNION ALL SELECT 'quests',        COUNT(*) FROM public.quests;
