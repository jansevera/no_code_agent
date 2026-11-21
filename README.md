# no_code_agent: EV quartet referee in n8n

A chat agent built in **n8n** (no code). You ask it about the EV quartet card game
in plain language, the LLM decides which tools to use, the tools read the card
database and do the calculations, and the LLM writes the answer.

```
Chat ──▶ AI Agent ──▶ answer
           │
           ├─ Chat model:  Unsloth Studio (local LLM, OpenAI-compatible API)
           ├─ Memory:      Simple Memory (last 10 messages of the chat)
           └─ Tools:
                query_cards_db         Postgres, read-only SELECT written by the LLM
                compare_cards          Code tool, who wins a round (lower wins for 0-100 and consumption)
                calculate_consumption  Code tool, kWh/100 km = battery / range × 100
                best_in_set            Postgres, ranks the 4 cards of a set on one stat (fixed query)
                best_in_deck           Postgres, ranks all 32 cards: 1 = best, 2 = 2nd best, -1 = worst (fixed query)
```

## Files

| File | What it is |
|---|---|
| `quartet-agent-workflow.json` | The n8n workflow (the homework deliverable). Import it into n8n. |
| `docker-compose.yml` | Postgres 16 with the card database, runs next to your n8n container |
| `db/init.sql` | Creates the table, loads the 32 cards, creates the read-only user |

## Database

Table `cards`: 32 cards, sets A–H (Sedans, Family SUVs, City cars, Luxury, Big SUVs,
Made in China, Supercars, Compact crossovers).

| Column | Meaning | Wins |
|---|---|---|
| `card_id`, `set_letter`, `set_theme` | e.g. `A1`, `A`, `Sedans` | |
| `car_name`, `car_name_ascii`, `car_version` | `Škoda Enyaq`, `Skoda Enyaq`, `85 (MY25)` | |
| `range_km` | WLTP range | higher |
| `acc_0_100_s` | 0–100 km/h in seconds | **lower** |
| `top_speed_kmh` | top speed | higher |
| `battery_kwh` | usable battery | higher |
| `consumption_kwh_100km` | calculated by Postgres: battery / range × 100 | **lower** |

The agent logs in as `quartet_reader` / `reader`, a user that can only SELECT.
`query_cards_db` lets the LLM write its own SQL, so it must not be able to delete or
change cards. (`quartet` / `quartet` is the owner, for you only.)

## Setup

1. **Start the database** (in this folder):
   ```
   docker compose up -d
   ```
   It listens on port 55432 on your PC. Your existing n8n container stays as it is.
   To load the cards again from scratch: `docker compose down -v` and `docker compose up -d`.

2. **Start Unsloth Studio** with a model that supports tool calling
   (e.g. `unsloth/gemma-4-E4B-it-GGUF:UD-Q4_K_XL`) and create an API key:
   avatar (bottom left) → Settings → API → Create.

3. **Import the workflow** in n8n: Workflows → Create → `...` menu → Import from File →
   `quartet-agent-workflow.json`.

4. **Create 2 credentials** in n8n (n8n runs in Docker, so the host is
   `host.docker.internal`, not `localhost`):

   | Credential | Type | Settings |
   |---|---|---|
   | Unsloth Studio | OpenAI | API Key: `sk-unsloth-...`, Base URL: `http://host.docker.internal:8888/v1` |
   | Quartet DB (read-only) | Postgres | Host `host.docker.internal`, Port `55432`, Database `quartet`, User `quartet_reader`, Password `reader`, SSL disable |

   Then open the nodes with a red warning and pick the matching credential:
   the chat model node → Unsloth Studio, `query_cards_db`, `best_in_set` and `best_in_deck` → Quartet DB (read-only).

5. In the chat model node, check the model name: it is set to
   `unsloth/gemma-4-E4B-it-GGUF:UD-Q4_K_XL`. If you loaded another model,
   pick it from the list (or type its id).

6. Click **Open chat** (bottom of the editor) and ask.

## Try these

- `Compare Tesla Model 3 and Skoda Enyaq on range, who wins?`
- `Which car in set G is fastest from 0 to 100?`
- `Which card has the lowest consumption in the whole deck?`
- `Porovnej Kia EV6 a BYD Seal ve spotřebě, kdo vyhraje?`
- `How much would a car with a 60 kWh battery and 400 km range use per 100 km?`
- `Which card has the 2nd worst range in the whole deck?`

In the execution log (Executions tab, or the logs panel under the chat) you can see
every tool call the agent made with its input and output.

## If something doesn't work

- **Credential test for Unsloth fails / no connection:** n8n in Docker can't see
  `127.0.0.1` of your PC, that's why the URL uses `host.docker.internal`. If it
  still can't connect, Unsloth Studio is probably listening only on 127.0.0.1;
  start it so it listens on `0.0.0.0`.
- **The agent answers without calling any tool:** some Unsloth Studio versions did
  not pass tools to GGUF models (issue unslothai/unsloth#4999). Update Unsloth, or
  run `llama-server --jinja` with the same model and point the Base URL at it.
- **Workflow import complains about node versions:** the workflow uses current node
  versions and was tested on n8n 2.48. Update the n8n image to a recent version.
- **Postgres: connection refused:** `docker compose ps` should show `quartet-db` running.
