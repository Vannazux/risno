exports.url = (site, region, page_num) ->
  if site.region_id
    throw "Unknown region " + region unless site.region_id[region]
    region = site.region_id[region]
  replace = (format) ->
    format = format.replace /HOST/, site.host
    format = format.replace /REGION/, region
    format = format.replace /PAGE/, page_num

  if Array.isArray site.url_sequence
    replace format for format in site.url_sequence
  else
    [replace site.url_sequence]

exports.find_ads = (context, site) ->
  context.find(site.ads)

exports.parse_ad = (ad, site) ->
  site = {} unless site
  selectors = site.selectors || {}
  price = clear_price ad.find(selectors.price).text()

  description: strip ad.find(selectors.description).text()
  location: strip ad.find(selectors.location).text()
  price: price
  img: find_image ad, site.host
  url: find_url ad, site.host
  site_name: site.name

find_image = (ad, host) ->
  img = ad.find('img[original]')
  src = if img.length > 0 then img.attr('original') else ad.find('img').attr('src')

  absolutize src, host if src
  
find_url = (ad, host) ->
  a = ad.find('a.idTag_PARTAGER')
  if a.length > 0
    crappy_pages_jaunes_url(a)
  else
    a = ad.find('.link-wrapper') #avendrealouer specific
    if a.length > 0
      absolutize a.attr('href'), host
    else
      a = ad.parent('a')
      if a.length > 0
        absolutize a.attr('href'), host
      else
        absolutize ad.find('a').attr('href'), host

absolutize = (url, host) ->
  if /^http:/.test(url)
    url
  else
    'http://' + host + url

strip = (string) ->
  string.replace(/\s+/g, ' ').replace(/^\s/, '').replace(/\s$/, '')

clear_price = (price) ->
  price = price.replace /\s/g, ''
  price = /[0-9]+/.exec(price)
  price[0] if price

crappy_pages_jaunes_url = (a) ->
  param = /\?idAnnonce=[^']*/.exec(a.attr('data-pjonglet'))
  'http://www.pagesjaunes.fr/verticales/immo/afficherFicheDetaillee.do' + param