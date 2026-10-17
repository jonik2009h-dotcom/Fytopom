# Fytopom – nasazení na internet krok za krokem

Výsledek: aplikace poběží na adrese `https://tvojejmeno.streamlit.app` (zdarma, s HTTPS, takže funguje i fotoaparát).
Vlastní doménu Streamlit Community Cloud v dokumentaci nenabízí; pokud ji chceš, použij Docker hosting (viz konec).

Co potřebuješ mít: účet na GitHubu, účet na Supabase, API klíč ke Gemini.

---------------------------------------------------------------------
## KROK 1 – Supabase (databáze a přihlašování)

1. Na supabase.com si založ projekt (nebo použij ten, co máš).
2. Vlevo **SQL Editor** → New query → vlož celý obsah souboru `supabase_schema.sql` → **Run**.
   Potvrď varování o `drop table`. Pak vlevo v **Table Editor** uvidíš čtyři tabulky:
   `stromy_uzivatele`, `archiv_analyz`, `komunitni_mapa`, `rate_limits`.
3. Zkopíruj si dvě hodnoty (**Project Settings → API / API Keys**):
   - **Project URL** (tvar `https://xxxx.supabase.co`)
   - **anon / publishable** klíč. NIKDY ne `service_role` / secret klíč.
   Když by přihlášení hlásilo „Invalid API key“, zkus v téže sekci záložku *Legacy* a použij tamní `anon` klíč.
4. **Authentication → URL Configuration**: *Site URL* nastav později na adresu aplikace (Krok 5).
5. **Authentication → Sign In / Providers → Email**: potvrzování e-mailů (Confirm email) zapnuté = noví lidé se musí prokliknout odkazem v e-mailu. Pro první test ho klidně vypni.

## KROK 2 – Gemini API klíč

1. Na aistudio.google.com → **Get API key** → vytvoř klíč a zkopíruj ho.
2. V Google Cloud Console nastav u projektu **limit útraty / upozornění**. Veřejná aplikace s AI je lákavá pro zneužití.

## KROK 3 – Nahrání na GitHub (z Linuxu na Chromebooku)

1. Na github.com si založ účet a vytvoř nový repozitář (např. `fytopom`). Nic v něm nezaškrtávej (žádné README, žádný .gitignore).
2. Do jedné složky (např. `~/fytopom`) dej všechny tyto soubory (včetně skrytých složek):
   `app.py`, `requirements.txt`, `packages.txt`, `.gitignore`, `README.md`, `DEPLOY.md`,
   `supabase_schema.sql`, `Dockerfile`, `.dockerignore`, `.streamlit/config.toml`, `.streamlit/secrets.toml.example`.
3. V Linux terminálu:
```bash
sudo apt update && sudo apt install -y git
git config --global user.name "Tvoje Jméno"
git config --global user.email "tvuj@email.cz"
cd ~/fytopom
git init
git branch -M main
git add .
```
4. **Než uděláš commit, zkontroluj, že se do gitu nedostanou klíče:**
```bash
git status
git check-ignore -v .streamlit/secrets.toml
```
   V seznamu z `git status` NESMÍ být `secrets.toml` ani `.env`. Druhý příkaz musí vypsat, že je soubor ignorovaný.
   (`secrets.toml.example` v seznamu být smí, je v něm jen vzor bez klíčů.)
5. Commit a odeslání:
```bash
git commit -m "Fytopom - první verze"
git remote add origin https://github.com/TVOJE_JMENO/fytopom.git
git push -u origin main
```
   GitHub po tobě chce heslo. Heslo k účtu už nefunguje, musíš zadat **Personal Access Token**:
   GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token,
   u repozitáře `fytopom` nastav *Contents: Read and write*. Token zkopíruj a vlož místo hesla.
6. Na stránce repozitáře na GitHubu zkontroluj, že jsou soubory nahoře a že tam NENÍ `secrets.toml`.

Pozdější změny: `git add .` → `git commit -m "popis"` → `git push`. Streamlit Cloud se pak sám aktualizuje.

## KROK 4 – Nasazení na Streamlit Community Cloud

1. Jdi na share.streamlit.io a přihlas se přes GitHub (povol přístup k repozitářům).
2. **Create app** → vyber repozitář `fytopom`, větev `main`, soubor `app.py`.
3. **App URL**: zadej vlastní jméno (6 až 63 znaků), např. `fytopom-sad` → adresa bude `https://fytopom-sad.streamlit.app`.
   Vyber ho hned, ať se v Googlu neindexuje náhodná adresa.
4. **Advanced settings**:
   - Python version: **3.12**
   - Secrets: vlož (s vlastními hodnotami, přesně v tomto tvaru):
```toml
GEMINI_API_KEY = "tvuj-gemini-klic"
SUPABASE_URL = "https://xxxx.supabase.co"
SUPABASE_KEY = "tvuj-anon-klic"
```
5. **Deploy**. První start trvá pár minut (instaluje se `requirements.txt` a font z `packages.txt`).

## KROK 5 – Dokončení v Supabase

1. V Supabase → **Authentication → URL Configuration**: *Site URL* = adresa tvé aplikace (`https://fytopom-sad.streamlit.app`).

## KROK 6 – Vyzkoušej celý průchod (důležité, nic z toho jsem nemohl spustit)

1. Otevři aplikaci jako host: funguje určení odrůdy, určení choroby (galerie i focení), vidíš komunitní mapu?
2. Zaregistruj se (potvrď e-mail, pokud je zapnutý) a přihlas se.
3. Přidej strom na mapu. Odhlas se a otevři mapu jako host: strom tam musí být vidět.
4. Udělej analýzu, ulož ji do archivu, stáhni PDF protokol (diakritika v PDF musí být v pořádku).
5. Přidej strom do deníku, obnov stránku (F5) a ověř, že tam zůstal.

Když něco selže: na Streamlit Cloudu klikni vpravo dole na **Manage app** → logy. Chybu pošli i mně.

---------------------------------------------------------------------
## Co je dobré vědět

- Zdarma aplikace na Community Cloudu se při delší nečinnosti uspí; první návštěvník ji pak jedním kliknutím probudí. Zdarma Supabase projekt se může při delší nečinnosti pozastavit; v dashboardu ho pak stačí obnovit.
- Veřejné aplikace na Community Cloudu se indexují vyhledávači.
- **Plochy sadu** (`plochy_sadu`) jsou pořád jen v paměti relace. Stromy v databázi zůstávají, ale seznam ploch po obnovení stránky zmizí.
- Přístupový token se po vypršení (cca 1 hodina) neobnovuje; uživatel se pak musí znovu přihlásit.
- Omezovač požadavků používá IP z hlavičky `X-Forwarded-For`; je to rozumná ochrana proti běžnému zneužití, ne neprolomitelná zeď.
- Tabulku `rate_limits` občas promaž (obsahuje IP adresy, GDPR), příkaz je na konci `supabase_schema.sql`.
- Komunitní mapa je veřejná včetně e-mailů autorů inzerátů. Napiš to uživatelům, ať o tom vědí.

## Alternativa: vlastní doména přes Docker
Soubor `Dockerfile` je připravený pro Render, Fly.io, Railway, Cloud Run nebo vlastní server. Proměnné `GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_KEY` nastav jako environment variables u hostingu, doménu pak napojíš u něj. Hosting musí mít HTTPS a podporovat WebSockety.
```bash
docker build -t fytopom .
docker run -p 8501:8501 -e GEMINI_API_KEY=... -e SUPABASE_URL=... -e SUPABASE_KEY=... fytopom
```
