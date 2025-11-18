import requests
from bs4 import BeautifulSoup

open('url.txt','w')
# QFED 数据主页 URL
url = "https://portal.nccs.nasa.gov/datashare/iesa/aerosol/emissions/QFED/v2.6r1/0.1/QFED/Y2018/M07/"  # 或者你直接访问具体的 QFED 文件目录页面

# 发送 GET 请求获取网页内容
response = requests.get(url)
soup = BeautifulSoup(response.text, 'html.parser')

# 提取所有 <a> 标签中的链接
links = soup.find_all('a', href=True)

# 提取所有 .nc 数据文件的链接
qfed_links = [link['href'] for link in links if link['href'].endswith('.nc4')]

# 输出所有数据文件的 URL
for link in qfed_links:
    print("https://portal.nccs.nasa.gov/datashare/iesa/aerosol/emissions/QFED/v2.6r1/0.1/QFED/Y2018/M07/" + link)
    with open('url.txt','a') as f:
        f.write("https://portal.nccs.nasa.gov/datashare/iesa/aerosol/emissions/QFED/v2.6r1/0.1/QFED/Y2018/M07/" + link + '\n')