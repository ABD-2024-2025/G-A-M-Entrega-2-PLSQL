import subprocess
import matplotlib.pyplot as plt
import datetime
from collections import defaultdict
import os

# Ejecutar un comando git para obtener fecha y autor de cada commit
cmd = ['git', 'log', '--pretty=%cd|%an', '--date=iso']
result = subprocess.run(cmd, stdout=subprocess.PIPE, text=True)
lines = result.stdout.splitlines()

# Diccionario para agrupar los commits por fecha y autor
# data[fecha][autor] = número de commits
data = defaultdict(lambda: defaultdict(int))
autores = set()

for line in lines:
    try:
        date_str, author = line.split('|', 1)
        # Convertir la fecha en formato ISO a un objeto datetime
        fecha_obj = datetime.datetime.fromisoformat(date_str.strip())
        dia = fecha_obj.date()
        data[dia][author.strip()] += 1
        autores.add(author.strip())
    except Exception as e:
        print(f"Error procesando la línea '{line}': {e}")

# Ordenar las fechas y los autores
fechas = sorted(data.keys())
autores = sorted(autores)

# Preparar los datos para el gráfico: para cada autor se construye una lista con la cantidad de commits por día
datos_apilados = {autor: [] for autor in autores}
for dia in fechas:
    for autor in autores:
        datos_apilados[autor].append(data[dia].get(autor, 0))

# Crear el directorio si no existe
output_directory = '/assets'
os.makedirs(output_directory, exist_ok=True)

# Graficar barras apiladas
plt.figure(figsize=(12, 6))
bottom = [0] * len(fechas)
for autor in autores:
    aportes = datos_apilados[autor]
    plt.bar(fechas, aportes, bottom=bottom, label=autor)
    # Sumar el aporte actual para ajustar la posición del siguiente conjunto
    bottom = [b + a for b, a in zip(bottom, aportes)]

plt.xlabel('Fecha')
plt.ylabel('Número de commits')
plt.title('Actividad del Repositorio por Colaborador')
plt.legend(title="Autores")
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig(os.path.join(output_directory, 'activity_graph.png'))
print("Gráfico generado correctamente.")