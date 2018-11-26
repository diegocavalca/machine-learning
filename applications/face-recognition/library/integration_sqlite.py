import os, sys, sqlite3

wdir =  os.getcwd()
sys.path.append(wdir)

# Configuracoes de execucao do Pipeline
from library import dlc

# Conexao com banco
def connection():
	try:
		db = sqlite3.connect(os.path.join(wdir, 'database_demo.db'))
		cursor = db.cursor()
		return db, cursor
	except Exception as e:
		print('-> ' + str(e))
		return None, None

def close(database):
	database.close()

def register(date, hour, camera, faces):
	if faces is not None:

		# Inserir registro(s)
		try:
			# OTIMIZAR THREAD
			db, cursor = connection()


			for face in faces:
				# VALIDACAO: verificar entrada/saida
				# ---
				# Padrao de nome da(s) camera(s): CAMERA_POSICAO (sem caracteres especiais)
				# 	Exemplo(s): 
				#		- ARENA-ENTRADA / ARENA-SAIDA
				#		- HIPICA-ENTRADA / HIPICA-SAIDA
				# 		...
				# REGRA: 
				#	- Entrada: Caso o ID (USUARIO) + CAMERANOME + POSICAO(ENTRADA) = N REGISTRADO -> REGISTRA
				#	- Saida: Caso o ID (USUARIO) + CAMERANOME + POSICAO(ENTRADA) = N REGISTRADO -> REGISTRA
				# 
				# PORTANTO ...
				#	ENTRADA:
				#		1) Se POSICAO==ENTRADA _E_ REGISTROS(ID+NOME+DATA) == PAR, entao >>> a pessoa n entrou (0) ou ela entrou e saiu (N mod 2==0): registra entrada
				#		2) Senao Se POSICAO==SAIDA _E_ REGISTROS(ID+NOME+DATA) == IMPAR, entrao >>> a pessoa entrou (1, 3, 5, ... N) mas n saiu: registra apenas saida
				# ---

				# Extrair posicao da cam
				cam_position = str(camera).upper().split('-')[-1]
				# Totalizar registros
				total = cursor.execute(
							'select COUNT(*) from registro where (DATA=? and `ID`=? and UPPER(NOME)=UPPER(?)) and ( CAMERA like "%ENTRADA" or CAMERA like "%SAIDA" )', 
							(str(date), face.id, face.name, )
						).fetchone()[0]
				# Validar: Regras 1) e 2) -> ACIMA!!
				r1 = ( cam_position.upper() == "ENTRADA" and (total % 2 == 0) )
				r2 = ( cam_position.upper() == "SAIDA" and not (total % 2 == 0) )
				if  r1 or r2:
					# Registrar!
					cursor.execute('''INSERT INTO registro (DATA, HORA, CAMERA, ID, NOME, PROBABILIDADE, L2)
						VALUES(?,?,?,?,?,?,?)''', (str(date), str(hour), str(camera), face.id, str(face.name), face.probability, face.l2))
			
			db.commit()
			close(db)

			return True
		except Exception as e:
			print('-->' + str(e))
			return str(e)

	else:
		return True
