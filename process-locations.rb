#!/usr/bin/env ruby

require 'rubygems'
  require 'nokogiri'
  require 'RMagick'
include Magick

$assets = './'
$output = './'
$stretch_layers = true

def process_street xml_file
  xml = Nokogiri::XML(File.read xml_file)
  game_object = xml.at_xpath('/game_object')
  tsid = game_object['tsid']

  layer_images = {}
  layer_image_data = {}

  gradient_top = game_object.at_xpath("//object[@id='gradient']/str[@id='top']").content.rjust(6, '0')
  gradient_bottom = game_object.at_xpath("//object[@id='gradient']/str[@id='bottom']").content.rjust(6, '0')

  street_l = Integer(game_object.at_xpath("//object[@id='dynamic']/int[@id='l']").content)
  street_r = Integer(game_object.at_xpath("//object[@id='dynamic']/int[@id='r']").content)
  street_t = Integer(game_object.at_xpath("//object[@id='dynamic']/int[@id='t']").content)
  street_b = Integer(game_object.at_xpath("//object[@id='dynamic']/int[@id='b']").content)
  street_w = street_r - street_l
  street_h = street_b - street_t

  street_data = {
      'tsid' => tsid,
      'l' => street_l,
      'r' => street_r,
      't' => street_t,
      'b' => street_b,
      'w' => street_w,
      'h' => street_h,
  }

  xml.search("//object[@id='layers']/object").each do |layer|
    layer_w = Integer(layer.at_xpath("int[@id='w']").content)
    layer_h = Integer(layer.at_xpath("int[@id='h']").content)
    layer_z = Integer(layer.at_xpath("int[@id='z']").content)
    layer_image_name = process_layer layer, street_data
    layer_images[layer_image_name] = layer_z
    layer_image_data[layer_image_name] = {'w' => layer_w, 'h' => layer_h}
  end

  # Then sort them by z-index
  layer_images = layer_images.sort_by {|k, v| v}

  full_image = Image.new street_w, street_h, GradientFill.new(0, 0, street_w, 0, "#%s" % [gradient_top], "#%s" % [gradient_bottom])
  # Save just the gradient
  full_image.write "%s/%s-gradient.png" % [$output, tsid]

  layer_images.each do |layer_image_name, z|
    data = layer_image_data[layer_image_name]
    layer_image = ImageList.new layer_image_name

    x = 0
    y = 0

    if $stretch_layers
      # The lower layers are smaller, scale them up for the full street image
      layer_image.sample! street_w, street_h
    else
      layer_w = data['w']
      layer_h = data['h']
      x = (street_w - layer_w)/2
      y = street_h - layer_h
    end

    full_image = full_image.composite layer_image, x, y, OverCompositeOp
  end

  full_image.write "%s/%s.png" % [$output, tsid]

end

def process_layer layer, street_data
  tsid = street_data['tsid']
  layer_id = layer['id']
  layer_w = Integer(layer.at_xpath("int[@id='w']").content)
  layer_h = Integer(layer.at_xpath("int[@id='h']").content)
  layer_image = Image.new layer_w, layer_h do |i|
    i.background_color= "none"
  end

  layer_image.background_color = 'none'
  objects = layer.search("object[@id='decos']/object")

  objects_z = {}

  # Store object ids
  objects.each do |object|
    object_id = object['id']
    object_z = Integer(object.at_xpath("int[@id='z']").content)
    objects_z[object_id] = object_z
  end

  # Then sort them by z-index
  objects_z = objects_z.sort_by {|k, v| v}

  objects_z.each do |oid, z|
    object = layer.search("object[@id='decos']/object[@id='#{oid}']")
    object_x = Integer(object.at_xpath("int[@id='x']").content)
    object_y = Integer(object.at_xpath("int[@id='y']").content)
    object_w = Integer(object.at_xpath("int[@id='w']").content)
    object_h = Integer(object.at_xpath("int[@id='h']").content)
    sprite = object.at_xpath("str[@id='sprite_class']").content

    flip = false
    flop = false

    h_flip = object.at_xpath("bool[@id='h_flip']")
    unless h_flip.nil?
      if h_flip.content == 'true'
        flop = true
      end
    end

    v_flip = object.at_xpath("bool[@id='v_flip']")
    unless v_flip.nil?
      if v_flip.content == 'true'
        flip = true
      end
    end

    r = object.at_xpath("int[@id='r']")

    image_path = "%s/%s.png" % [$assets, sprite]
    #puts "%s: %s" % [layer_id, sprite]

    if layer_id == 'middleground'
      object_x = object_x - street_data['l']
      object_y = object_y - street_data['t']
    end

    if File.exists? image_path
      object_image = ImageList.new image_path
      object_image.background_color = 'none'

      if flip
        object_image.flip!
      end

      if flop
        object_image.flop!
      end

      resized_object_image = object_image.sample object_w, object_h

      # All rotation occurs around bottom middle, so we'll pad this image with a transparent area
      # to move the centre of rotation to middle middle
      img = Image.new object_w, object_h * 2 do |i|
        i.background_color= "none"
      end
      padded_object_image = img.composite resized_object_image, 0, 0, OverCompositeOp

      unless r.nil?
        r_degrees = Integer(r.content)
        padded_object_image.rotate! r_degrees
      end

      layer_image = layer_image.composite padded_object_image,
                                          object_x - padded_object_image.columns/2,
                                          object_y - padded_object_image.rows/2, OverCompositeOp
    else
      puts "Image %s not found" % [sprite]
    end

  end

  #puts "Saving %s-%s.png" % [tsid, layer_id]
  layer_image_name = "%s/%s-%s.png" % [$output, tsid, layer_id]
  layer_image.write layer_image_name

  return layer_image_name
end


if ARGV.length == 3

  location_data = ARGV[0]
  asset_data = ARGV[1]
  output = ARGV[2]

  $assets = asset_data
  $output = output

  Dir.glob('%s/*.xml' % location_data) do |f|
    process_street f
  end

else

  puts "Usage: process-locations.rb <path to location xml files> <path to asset pngs> <path to output directory>"
end
