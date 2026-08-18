--1.find the wins of each Team
SELECT 
    winner,
    COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY total_wins DESC;


--2.Top 10 Run Scorers
SELECT batter,SUM(batsman_runs) AS total_runs
FROM deliveries
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;


--3.Top 10 wickets taker in IPL
SELECT 
    bowler,
    COUNT(*) AS total_wickets
FROM deliveries
WHERE dismissal_kind IS NOT NULL
  AND dismissal_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 10;


--4.Highest Individual Score in a Match
SELECT 
    match_id,
    batter,
    SUM(batsman_runs) AS individual_score
FROM deliveries
GROUP BY match_id, batter
ORDER BY individual_score DESC
LIMIT 10;


--5.Top 10 Players by Number of Sixes
SELECT 
    batter,
    COUNT(*) AS total_sixes
FROM deliveries
WHERE batsman_runs = 6
GROUP BY batter
ORDER BY total_sixes DESC
LIMIT 10;


---6.Top 10 Players by Number of Fours
SELECT 
    batter,
    COUNT(*) AS total_fours
FROM deliveries
WHERE batsman_runs = 4
GROUP BY batter
ORDER BY total_fours DESC
LIMIT 10;



--Check the columns available in deliveries
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'deliveries'
ORDER BY ordinal_position;



--7.Top 10 Batting Strike Rates,Minimum 500 balls faced
SELECT
    batter,
    SUM(batsman_runs) AS total_runs,
    COUNT(*) AS balls_faced,
    ROUND(
        (SUM(batsman_runs)::NUMERIC / COUNT(*)) * 100,
        2
    ) AS strike_rate
FROM deliveries
GROUP BY batter
HAVING COUNT(*) >= 500
ORDER BY strike_rate DESC
LIMIT 10;


--8.Top 10 Bowlers by Economy Rate,Minimum 300 deliveries
SELECT
    bowler,
    SUM(total_runs - batsman_runs) AS runs_conceded,
    COUNT(*) AS balls_bowled,
    ROUND(
        (SUM(total_runs - batsman_runs)::NUMERIC / COUNT(*)) * 6,
        2
    ) AS economy_rate
FROM deliveries
GROUP BY bowler
HAVING COUNT(*) >= 300
ORDER BY economy_rate ASC
LIMIT 10;



--9.Top 10 Players by Player of the Match Awards
SELECT
    player_of_match,
    COUNT(*) AS awards
FROM matches
WHERE player_of_match IS NOT NULL
GROUP BY player_of_match
ORDER BY awards DESC
LIMIT 10;


--10.Toss Decision vs Match Result
SELECT
    toss_decision,
    COUNT(*) AS total_matches,
    SUM(
        CASE 
            WHEN toss_winner = winner THEN 1
            ELSE 0
        END
    ) AS toss_winner_match_wins,
    ROUND(
        SUM(
            CASE 
                WHEN toss_winner = winner THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS win_percentage
FROM matches
WHERE toss_winner IS NOT NULL
  AND winner IS NOT NULL
GROUP BY toss_decision
ORDER BY win_percentage DESC;



--11.Toss Wins Converted into Match Wins
SELECT
    toss_winner,
    COUNT(*) AS toss_wins,
    SUM(
        CASE
            WHEN toss_winner = winner THEN 1
            ELSE 0
        END
    ) AS match_wins_after_toss,
    ROUND(
        SUM(
            CASE
                WHEN toss_winner = winner THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS conversion_percentage
FROM matches
WHERE toss_winner IS NOT NULL
  AND winner IS NOT NULL
GROUP BY toss_winner
ORDER BY conversion_percentage DESC;



--12.Highest Team Score in a Match
SELECT
    batting_team,
    MAX(team_score) AS highest_score
FROM (
    SELECT
        match_id,
        inning,
        batting_team,
        SUM(total_runs) AS team_score
    FROM deliveries
    GROUP BY match_id, inning, batting_team
) AS match_scores
GROUP BY batting_team
ORDER BY highest_score DESC;



--13.Average Team Score per Innings
SELECT
    batting_team,
    ROUND(AVG(team_score), 2) AS average_score,
    COUNT(*) AS innings_played
FROM (
    SELECT
        match_id,
        inning,
        batting_team,
        SUM(total_runs) AS team_score
    FROM deliveries
    GROUP BY match_id, inning, batting_team
) AS innings_scores
GROUP BY batting_team
HAVING COUNT(*) >= 20
ORDER BY average_score DESC;


--14.Season-wise Team Wins
SELECT
    season,
    winner AS team,
    COUNT(*) AS wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, wins DESC;


--15.Top Run Scorer in Each IPL Season(Uses JOIN + GROUP BY + Window Function)

WITH player_season_runs AS (
    SELECT
        m.season,
        d.batter,
        SUM(d.batsman_runs) AS total_runs
    FROM deliveries d
    JOIN matches m
        ON d.match_id = m.id
    GROUP BY m.season, d.batter
),
ranked_players AS (
    SELECT
        season,
        batter,
        total_runs,
        RANK() OVER (
            PARTITION BY season
            ORDER BY total_runs DESC
        ) AS rank
    FROM player_season_runs
)
SELECT
    season,
    batter,
    total_runs
FROM ranked_players
WHERE rank = 1
ORDER BY season;