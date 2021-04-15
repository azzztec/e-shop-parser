require 'curb'
require 'nokogiri'
require 'csv'
require 'uri'

def get_filename
  puts "Enter file name:"
  return gets
end

def get_url
  puts "Enter URL:"
  #URI.encode and .strip methods validate the url
  return URI.encode(gets.strip)
end

filename = get_filename()
url  = get_url()
#variable i is needed to find out if the product page is "multiproduct"
# and how many product varieties it has
i = 0
data = []
product_title = ''
product_img_url = ''
product_price = {
    "weight" => [],
    "cost" => []
}


#getting HTML of category page
http_category = Curl.get(url) do |http|
  http.headers['User-Agent'] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.132 Safari/537.36"
end
html_category = Nokogiri::HTML(http_category.body_str)

puts "\n", "getting data..."
#//a[@class='product-name'] because it contains link to its own page with product info
html_category.xpath("//a[@class='product-name']").each do |product|
  link  = product["href"].to_s

  if link != ''
    #getting HTML of a single product page
    http_product = Curl.get(link)
    html_product = Nokogiri::HTML(http_product.body_str)

    product_title = html_product.xpath("//h1[@class='product_main_name']").text()
    product_img_url = html_product.xpath("//img[@id='bigpic']/@src").to_s

    html_product.xpath("//span[@class='radio_label']").each do |weight|
      product_price["weight"].push(weight.text())
    end

    html_product.xpath("//span[@class='price_comb']").each do |cost|
      product_price["cost"].push(cost.text())
    end

    data.push(
        {
            "product_title" => product_title,
            "product_img_url" => product_img_url,
            "product_price" => product_price
        }
    )
    product_price = {
        "weight" => [],
        "cost" => []
    }
    i += 1
  end
end

puts "\n", "creating file..."
#creating csv filee
CSV.open("./#{filename}.csv", "wb") do |csv|
  data.each do |item|
    for i in 0..(item["product_price"]["cost"].length - 1) do
      if item["product_price"]["cost"][i] != "" then
        csv << [
            "#{item["product_title"]} - #{item["product_price"]["weight"][i]}",
            "#{item["product_price"]["cost"][i]}",
            "#{item["product_img_url"]}"
        ]
      end
    end
  end
end