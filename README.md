# Fytopom 🍎

Určování odrůd ovocných stromů a diagnostika chorob (Streamlit + Supabase + Google Gemini).

Nasazení krok za krokem (Supabase, GitHub, Streamlit Community Cloud): viz `DEPLOY.md`.
Databáze: `supabase_schema.sql`.

## Lokální spuštění
```bash
pip install -r requirements.txt
cp .streamlit/secrets.toml.example .streamlit/secrets.toml   # doplň vlastní klíče
streamlit run app.py
```
