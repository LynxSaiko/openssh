import re

# Lokasi file certdata.txt
certdata_path = "/etc/ssl/certdata.txt"

# Lokasi output untuk menyimpan sertifikat .crt
certs_dir = "/usr/local/share/mozilla/"

# Membaca file certdata.txt
with open(certdata_path, 'r') as file:
    data = file.read()

# Regex untuk mengekstrak bagian sertifikat dari certdata.txt
certs = re.findall(r"-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----", data, re.S)

# Menyimpan setiap sertifikat ke file .crt
for i, cert in enumerate(certs):
    cert_filename = f"{certs_dir}mozilla_cert_{i+1}.crt"
    with open(cert_filename, 'w') as cert_file:
        cert_file.write("-----BEGIN CERTIFICATE-----\n")
        cert_file.write(cert)
        cert_file.write("\n-----END CERTIFICATE-----\n")

    print(f"Sertifikat disimpan di: {cert_filename}")
