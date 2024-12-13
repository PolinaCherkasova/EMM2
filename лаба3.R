# 3 Лабораторная работа: AR(p)ARCH(q) и реальные данные
# 1. Реализовать AR(2)ARCH(3) процесс из n = 2100 наблюдений с значениями 
# параметров 𝜃= (−0.3, 0.4)′, 𝐴 = (1, 0.2, 0.1, 0.2)′ и построить его график.

n = 2100 # кол-во наблюдений
theta = c(-0.3, 0.4)
A = c(1, 0.2, 0.1, 0.2) # вектор значений ai

# Функция для AR(2)ARCH(3) процесса
AR2_ARCH3 = function(a, theta) 
{
  x = numeric(n) # значения процесса
  sigma = numeric(n)
  eps = rnorm(n,0,1) # ошибки
  # Начальные значения
  sigma[1] = a[1]
  x[1] = sqrt(sigma[1])*eps[1]
  sigma[2] = a[1] + a[2]*x[1]^2 
  x[2] = theta[1]*x[1] + sqrt(sigma[2])*eps[2]
  sigma[3] = a[1] + a[2]*x[2]^2 + a[3]*x[1]^2
  x[3] = theta[1]*x[2] + theta[2]*x[1] + sqrt(sigma[3])*eps[3]
  # Основной цикл
  for (i in 4:n) 
  {
    sigma[i] = a[1] + a[2]*x[i-1]^2 + a[3]*x[i-2]^2 + a[4]*x[i-3]^2
    x[i] = theta[1]*x[i-1] + theta[2]*x[i-2] + sqrt(sigma[i])*eps[i]
  }
  plot(x, type = 'l', main = "AR(2)ARCH(3) процесс:") # график процесса
  x
}
  
x = AR2_ARCH3(A, theta)

# 2. Разделить, полученную на первом шаге последовательность {xn}, 
# в отношении 20 : 1 на обучающую и тестовую выборки соответственно.

n1 = 2000 # Разделение выборки 2000 к 100
n2 = 100

h_train = x[1 : n1] # Обучающая выборка (1:2000)
h_test = x[(n1+1) : n] # Тестовая выборка (2001:2100)

# 3. На основе обучающей выборки получить оценки параметров 𝜃 = (𝜃1, 𝜃2)′ и 𝐴 = (𝑎0, 𝑎1, 𝑎2, 𝑎3)′.
library("tseries")
# Оценка параметра 𝜃 для процесса AR(2)
a = arima(h_train, order = c(2, 0, 0), include.mean = FALSE)
theta1 = c(a$coef[1], a$coef[2]); theta1

h = numeric(n1)
# Начальные значения
h[1] = h_train[1]
h[2] = h_train[2] - theta1[1]*h_train[1]
# Основной цикл
for (i in 3 : n1)
{
  h[i] = h_train[i] - theta1[1]*h_train[i-1] - theta1[2]*h_train[i-2]
}
# Оценка параметра A для процесса ARCH(3)
g = garch(h, order = c(0, 3), start = A)
A1 = c(g$coef[1], g$coef[2], g$coef[3], g$coef[4]); A1

# 4. Построить последовательность прогнозов на один шаг на тестовой выборке. 
# Наложить последовательность прогнозов на последовательность наблюдений процесса. 

# график процесса
plot(h_test, type = 'l', col = 'turquoise', main = "График посл прогнозов и наблюдений процесса:")
prediction = function(h_test, theta, a) 
{
  x = array(n2) # посл прогнозов на 1 шаг {𝑥𝑛+1|𝑛}
  sigma = array(n2)
  upbound = array(n2) # верхняя и нижняя границы прогноза 
  lbound = array(n2)
  # Начальные значения  
  x[1] = 0
  x[2] = theta[1]*h_test[1]
  x[3] = theta[1]*h_test[2] + theta[2]*h_test[1]
  sigma[1] = a[1]
  sigma[2] = a[1] + a[2]*h_test[1]^2
  sigma[3] = a[1] + a[2]*h_test[2]^2 + a[3]*h_test[1]^2
  # Основной цикл нахождения посл прогнозов
  for(i in 4 : n2) 
  {
    x[i] = theta[1]*h_test[i-1] + theta[2]*h_test[i-2]
    sigma[i] = a[1] + a[2]*h_test[i-1]^2 + a[3]*h_test[i-2]^2 + a[4]*h_test[i-3]^2
  } 
  for(i in 1 : n2) # Нахождение границ
  {
    upbound[i] = x[i] + sqrt(sigma[i])
    lbound[i] = x[i] - sqrt(sigma[i])
  }
  
  lines(x, type = 'p', col = 'black') # Наложение посл прогнозов на один шаг на посл наблюдений процесса
  # Наложение границ прогноза волатильности процесса
  lines(upbound, lty = 2, col = 'red')
  lines(lbound, lty = 2, col = 'red')
}

prediction(h_test, theta1, A1)

# 5. Скачать с сайта https://www.finam.ru/ любые дневные котировки финансовых 
# активов или значения индексов (минимум за 3 года). 
# 6. Импортировать скачанные данные в R, используя функцию readtable();

# Я взяла данные Газпрома за 4 года
data = read.csv("C:\\Users\\cherk_3rh9yom\\OneDrive\\Рабочий стол\\ЭММ2\\GAZP_201101_241101.csv", sep = ";")
str(data)

# 7. Построить график динамики актива
plot(data$X.HIGH, type = 'l', main = "График динамики актива:") 

# 8. Привести данные к стационарному виду, используя одно из преобразований
# zk = (𝑃𝑘 − 𝑃𝑘−1) /𝑃𝑘−1, или zk = ln 𝑃𝑘/𝑃𝑘−1, 𝑘 ≥ 1.
# 9. Построить график доходностей {zk} финансового актива;
p = data$X.HIGH
z = array(nrow(data))
z[1] = 0
for(k in 2 : nrow(data))
  z[k] = log(p[k]/p[k - 1])
plot(z, type = 'l', main = "График доходностей {zk} финансового актива:")

# 10. Повторить шаги 2-4 для последовательности {zn} при предположении,
# что процесс {zn} описывается моделью AR(2)ARCH(3).

# 2) Разделить, полученную последовательность {zn}, в отношении 20 : 1
# на обучающую и тестовую выборки соответственно.

n = nrow(data); n # Объем данных
# Вычисление размера обучающей и тестовой выборок
train_size = floor(0.95 * n); train_size
test_size = n - train_size; test_size
# Разделение данных на обучающую и тестовую выборки
z_train = z[1:train_size]
z_test = z[(train_size+1):n]

# 3) На основе обучающей выборки получить оценки параметров 𝜃 = (𝜃1, 𝜃2)′ и 𝐴 = (𝑎0, 𝑎1, 𝑎2, 𝑎3)′.
# Оценка параметра 𝜃 для процесса AR(2)
a2 = arima(z_train, order = c(2, 0, 0), include.mean = FALSE)
theta1 = c(a2$coef[1], a2$coef[2]); theta1

zz = numeric(train_size)
# Начальные значения
zz[1] = z_train[1]
zz[2] = z_train[2] - theta1[1]*z_train[1]
# Основной цикл
for (i in 3 : train_size)
{
  zz[i] = z_train[i] - theta1[1]*z_train[i-1] - theta1[2]*z_train[i-2]
}
# Оценка параметра A для процесса ARCH(3)
g = garch(zz, order = c(0, 3), start = A)
A1 = c(g$coef[1], g$coef[2], g$coef[3], g$coef[4]); A1

# 4) Построить последовательность прогнозов на один шаг на тестовой выборке. 
# Наложить последовательность прогнозов на последовательность наблюдений процесса. 

# график процесса
plot(z_test, type = 'l', col = 'turquoise', main = "График посл прогнозов и наблюдений процесса:")
prediction = function(z_test, theta, a) 
{
  x = array(n2) # посл прогнозов на 1 шаг {z𝑛+1|𝑛}
  sigma = array(n2)
  upbound = array(n2) # верхняя и нижняя границы прогноза 
  lbound = array(n2)
  # Начальные значения  
  x[1] = 0
  x[2] = theta[1]*z_test[1]
  x[3] = theta[1]*z_test[2] + theta[2]*z_test[1]
  sigma[1] = a[1]
  sigma[2] = a[1] + a[2]*z_test[1]^2
  sigma[3] = a[1] + a[2]*z_test[2]^2 + a[3]*z_test[1]^2
  # Основной цикл нахождения посл прогнозов
  for(i in 4 : n2) 
  {
    x[i] = theta[1]*z_test[i-1] + theta[2]*z_test[i-2]
    sigma[i] = a[1] + a[2]*z_test[i-1]^2 + a[3]*z_test[i-2]^2 + a[4]*z_test[i-3]^2
  } 
  for(i in 1 : n2) # Нахождение границ
  {
    upbound[i] = x[i] + sqrt(sigma[i])
    lbound[i] = x[i] - sqrt(sigma[i])
  }
  
  lines(x, type = 'p', col = 'black') # Наложение посл прогнозов на один шаг на посл наблюдений процесса
  # Наложение границ прогноза волатильности процесса
  lines(upbound, lty = 2, col = 'red')
  lines(lbound, lty = 2, col = 'red')
}

prediction(z_test, theta1, A1)
