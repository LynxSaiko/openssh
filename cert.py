import re

certs_dir = "/usr/local/share/mozilla/"

# Baca file certdata.txt
with open("/etc/ssl/certdata.txt", "r") as f:
    cert_data = f.read()

# Ekstrak sertifikat dari certdata.txt menggunakan regex
certs = re.findall(r"^CKA_CERTIFICATE\s+\"([^\"]+)\"\s+(.+?)^CKA_END", cert_data, re.S | re.M)

# Buat file untuk setiap sertifikat
for cert in certs:
    cert_name = cert[0].replace("/", "_").replace(":", "_")
    cert_body = cert[1]
    cert_filename = certs_dir + cert_name + ".crt"
    
    with open(cert_filename, "w") as cert_file:
        cert_file.write(cert_body)
