import csv, random, uuid
from datetime import date, timedelta

random.seed(42)

N = 50
countries = ["nl", "de", "fr", "es", "br", "us", "uk", " it ", "pt"]
yn = ["true", "false", "yes", "no", "1", "0", " t ", " f "]

first_names = ["Alex","Sam","Taylor","Jordan","Riley","Casey","Morgan","Quinn","Jamie","Avery"]
last_names  = ["Stone","Rivera","Kim","Singh","Dubois","Khan","Novak","Silva","Santos","Murphy"]

rows = []
start = date(2024, 1, 1)

for i in range(N):
    cid = str(uuid.uuid4())[:8]
    fn = random.choice(first_names)
    ln = random.choice(last_names)
    email = f"{fn}.{ln}{random.randint(1,999)}@Example.COM"
    cc = random.choice(countries)
    sd = (start + timedelta(days=random.randint(0, 400))).isoformat()
    opt = random.choice(yn)
    # Sprinkle a few messy values
    if i % 10 == 0:
        email = "  " + email.upper() + "  "     # whitespace + uppercase
    if i % 13 == 0:
        cc = " nl "                             # odd spacing
    if i % 17 == 0:
        opt = "Y"                               # another truthy form
    rows.append([cid, fn, ln, email, cc, sd, opt])

# Add a couple of duplicate business keys to test dedupe
dup_id = rows[5][0]
rows.append([dup_id, rows[5][1], rows[5][2], rows[5][3], "NL", "2025-05-01", "true"])
dup_id2 = rows[7][0]
rows.append([dup_id2, rows[7][1], rows[7][2], rows[7][3], "de", "2025-02-11", "false"])

with open("data/customers.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["customer_id","first_name","last_name","email","country_code","signup_date","is_marketing_opt_in"])
    w.writerows(rows)
