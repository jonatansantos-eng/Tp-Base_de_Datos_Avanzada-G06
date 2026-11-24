"""
Universidad Nacional de La Matanza
Materia: 3641 - Bases de Datos Aplicada
Trabajo Practico: Sistema de registro y gestion del Mundial de Futbol

Script: scraping_arbitros.py
Objetivo: Extraer nomina historica y actual de arbitros de finales de la Copa del Mundo
          mediante scraping HTML real de Wikipedia (tabla wikitable), respetando
          las politicas de User-Agent de la Fundacion Wikimedia.
Salida: CSV normalizado listo para BULK INSERT en SQL Server.
"""

import csv
import os
import re
import unicodedata
import urllib.request
from datetime import datetime
from html.parser import HTMLParser

# User-Agent requerido por la Fundacion Wikimedia
USER_AGENT = "TPMundialUNLaM/1.0 (lacoria@alumno.unlam.edu.ar; Grupo06-BDDAplicada)"
WIKI_URL = "https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_referees"

# Mapeo basico de codigos FIFA/pais a confederacion
CONFEDERACIONES_POR_PAIS = {
    "ARG": "CONMEBOL", "BRA": "CONMEBOL", "URU": "CONMEBOL", "COL": "CONMEBOL",
    "CHI": "CONMEBOL", "ECU": "CONMEBOL", "PAR": "CONMEBOL", "VEN": "CONMEBOL",
    "BOL": "CONMEBOL", "PER": "CONMEBOL",
    "USA": "CONCACAF", "MEX": "CONCACAF", "CAN": "CONCACAF", "CRC": "CONCACAF",
    "JPN": "AFC", "KOR": "AFC", "JOR": "AFC", "QAT": "AFC", "IRN": "AFC", "KSA": "AFC",
    "MAR": "CAF", "RSA": "CAF", "EGY": "CAF", "SEN": "CAF",
}

# Fechas de nacimiento verificadas para arbitros principales conocidos
# (la tabla resumen de Wikipedia no incluye fecha de nacimiento)
FECHAS_NACIMIENTO_CONOCIDAS = {
    "Horacio Elizondo": "1963-11-04",
    "Nestor Pitana": "1975-06-17",
    "Néstor Pitana": "1975-06-17",
    "Pierluigi Collina": "1960-02-13",
    "Howard Webb": "1971-07-14",
    "Nicola Rizzoli": "1971-10-05",
    "Szymon Marciniak": "1981-01-07",
    "Ismail Elfath": "1982-03-03",
    "Slavko Vinčić": "1979-11-25",
    "Björn Kuipers": "1973-03-28",
    "Danny Makkelie": "1983-01-28",
    "Bastian Dankert": "1980-06-09",
    "Mauro Vigliano": "1975-08-05",
    "Massimiliano Irrati": "1979-06-27",
}


class WikiFinalsTableParser(HTMLParser):
    """Parser HTML sin dependencias externas para la primera wikitable de Wikipedia."""

    def __init__(self):
        super().__init__()
        self.in_table = False
        self.table_done = False
        self.in_row = False
        self.in_cell = False
        self.rows = []
        self.curr_row = []
        self.curr_cell = []

    def handle_starttag(self, tag, attrs):
        if self.table_done:
            return
        attrs_dict = dict(attrs)
        if tag == "table" and "wikitable" in attrs_dict.get("class", "") and not self.in_table:
            self.in_table = True
        elif self.in_table and tag == "tr":
            self.in_row = True
            self.curr_row = []
        elif self.in_row and tag in ("td", "th"):
            self.in_cell = True
            self.curr_cell = []

    def handle_endtag(self, tag):
        if self.table_done:
            return
        if tag == "table" and self.in_table:
            self.in_table = False
            self.table_done = True
        elif tag == "tr" and self.in_row:
            if self.curr_row:
                self.rows.append(self.curr_row)
            self.in_row = False
        elif tag in ("td", "th") and self.in_cell:
            texto = " ".join("".join(self.curr_cell).split())
            self.curr_row.append(texto)
            self.in_cell = False

    def handle_data(self, data):
        if self.in_cell:
            self.curr_cell.append(data)


def limpiar_ascii_slug(texto):
    normalizado = unicodedata.normalize("NFKD", texto)
    sin_acentos = "".join(c for c in normalizado if not unicodedata.combining(c))
    slug = re.sub(r"[^A-Za-z0-9]+", "_", sin_acentos).strip("_").upper()
    return slug[:60]


def parsear_html_arbitros(html):
    parser = WikiFinalsTableParser()
    parser.feed(html)

    if len(parser.rows) <= 1:
        raise ValueError("No se encontraron filas en la tabla wikitable de Wikipedia.")

    # Coincide con "Nombre Apellido (COD)" incluso cuando hay multiples arbitros en una celda
    patron_arbitro = re.compile(r"([A-ZÀ-ÖØ-ÞŁŚŻŹČĆŠŽĐ][^\(\)\[\]]+?)\s*\(([A-Z]{3})\)")
    roles_columnas = [
        (1, "Principal"),
        (2, "Asistente"),
        (3, "Cuarto Arbitro"),
        (4, "Reserva"),
        (5, "VAR"),
    ]

    consolidados = {}
    for fila in parser.rows[1:]:
        match_anio = re.search(r"(\d{4})", fila[0])
        if not match_anio:
            continue
        anio = match_anio.group(1)

        for idx_col, rol in roles_columnas:
            if idx_col >= len(fila):
                continue
            celda = re.sub(r"\[\d+\]", "", fila[idx_col]).strip()
            if not celda or celda in ("—", "-"):
                continue

            for match in patron_arbitro.finditer(celda):
                nombre_completo = match.group(1).strip().replace(",", "")
                codigo_pais = match.group(2).strip()
                clave_unica = (nombre_completo, codigo_pais)

                if clave_unica not in consolidados:
                    consolidados[clave_unica] = {
                        "nombre_completo": nombre_completo,
                        "codigo_pais": codigo_pais,
                        "rol_principal": rol,
                        "ediciones": [anio],
                    }
                elif anio not in consolidados[clave_unica]["ediciones"]:
                    consolidados[clave_unica]["ediciones"].append(anio)

    resultado = []
    for item in consolidados.values():
        nombre_completo = item["nombre_completo"]
        partes = nombre_completo.split(None, 1)
        nombres = partes[0]
        apellidos = partes[1] if len(partes) > 1 else partes[0]
        codigo_pais = item["codigo_pais"]
        confederacion = CONFEDERACIONES_POR_PAIS.get(codigo_pais, "UEFA")
        primer_anio = int(item["ediciones"][0])
        fecha_nac = FECHAS_NACIMIENTO_CONOCIDAS.get(
            nombre_completo,
            f"{primer_anio - 38}-01-01"
        )

        resultado.append({
            "clave_externa": f"WIKI_{codigo_pais}_{limpiar_ascii_slug(nombre_completo)}",
            "nombres": nombres,
            "apellidos": apellidos,
            "codigo_pais": codigo_pais,
            "confederacion": confederacion,
            "categoria": f"FIFA Elite - {item['rol_principal']}",
            "fecha_nacimiento": fecha_nac,
            # Se usa ';' en lugar de ',' para compatibilidad directa con BULK INSERT FIELDTERMINATOR=','
            "ediciones_mundial": "; ".join(item["ediciones"]),
        })

    return resultado


def obtener_arbitros_fallback():
    return [
        {"clave_externa": "ARB_ARG_01", "nombres": "Nestor", "apellidos": "Pitana", "codigo_pais": "ARG", "confederacion": "CONMEBOL", "categoria": "FIFA Elite - Principal", "fecha_nacimiento": "1975-06-17", "ediciones_mundial": "2014; 2018"},
        {"clave_externa": "ARB_BRA_01", "nombres": "Arnaldo", "apellidos": "Cezar Coelho", "codigo_pais": "BRA", "confederacion": "CONMEBOL", "categoria": "FIFA Elite - Principal", "fecha_nacimiento": "1943-01-15", "ediciones_mundial": "1982"},
        {"clave_externa": "ARB_FRA_01", "nombres": "Georges", "apellidos": "Capdeville", "codigo_pais": "FRA", "confederacion": "UEFA", "categoria": "FIFA Elite - Principal", "fecha_nacimiento": "1899-10-30", "ediciones_mundial": "1938"},
        {"clave_externa": "ARB_USA_01", "nombres": "Ismail", "apellidos": "Elfath", "codigo_pais": "USA", "confederacion": "CONCACAF", "categoria": "FIFA Elite - Cuarto Arbitro", "fecha_nacimiento": "1982-03-03", "ediciones_mundial": "2022"},
        {"clave_externa": "ARB_POL_01", "nombres": "Szymon", "apellidos": "Marciniak", "codigo_pais": "POL", "confederacion": "UEFA", "categoria": "FIFA Elite - Principal", "fecha_nacimiento": "1981-01-07", "ediciones_mundial": "2022"},
    ]


def obtener_arbitros():
    print(f"[{datetime.now()}] Iniciando scraping HTML en vivo desde: {WIKI_URL}")
    print(f"[{datetime.now()}] User-Agent: {USER_AGENT}")

    try:
        req = urllib.request.Request(WIKI_URL, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(req, timeout=15) as response:
            html = response.read().decode("utf-8")
        print(f"[{datetime.now()}] HTML descargado ({len(html)} bytes). Parseando tabla wikitable...")
        arbitros = parsear_html_arbitros(html)
        print(f"[{datetime.now()}] Scraping HTML exitoso: {len(arbitros)} arbitros unicos extraidos.")
        return arbitros
    except Exception as e:
        print(f"[{datetime.now()}] Aviso: Fallo conexion/parseo en vivo ({e}). Usando respaldo offline.")
        return obtener_arbitros_fallback()


def exportar_csv(arbitros, ruta_salida):
    os.makedirs(os.path.dirname(ruta_salida), exist_ok=True)
    columnas = [
        "clave_externa", "nombres", "apellidos", "codigo_pais",
        "confederacion", "categoria", "fecha_nacimiento", "ediciones_mundial"
    ]
    with open(ruta_salida, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=columnas, lineterminator="\n")
        writer.writeheader()
        writer.writerows(arbitros)
    print(f"[{datetime.now()}] Archivo generado exitosamente: {ruta_salida} ({len(arbitros)} registros)")


if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ruta_live = os.path.join(base_dir, "data", "live", "arbitros_scraping.csv")
    ruta_orig = os.path.join(base_dir, "data", "original", "arbitros_scraping.csv")
    datos = obtener_arbitros()
    exportar_csv(datos, ruta_live)
    exportar_csv(datos, ruta_orig)
