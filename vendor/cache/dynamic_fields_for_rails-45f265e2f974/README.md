# DynamicFieldsForRails
[![Gem Version](https://badge.fury.io/rb/dynamic_fields_for_rails.png)](http://badge.fury.io/rb/dynamic_fields_for_rails)
[![Dependency Status](https://gemnasium.com/mortik/dynamic_fields_for_rails.png)](https://gemnasium.com/mortik/dynamic_fields_for_rails)

Dynamic fields helper for Rails.

## Installation

Add this line to your application's Gemfile:

```
gem 'dynamic_fields_for_rails'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install dynamic_fields_for_rails
```

Add this to your application.coffee

```
#= require dynamic_fields_for
```

## Usage

Create a partial for your nested resource called "_{nested_resoure}_fields.haml" or with .html and so on.
Add to the partial only the fields you want to edit like this:

```
.fields
  = fields.label :field1
  = fields.text_field :field1
  
  = fields.label :field2
  = fields.text_field :field2
  
  = link_to_delete_fields fields, "Delete"
```

The "link_to_delete_fields" helper is a easy way to make the nested fields deletable. You can put whatever divs/fieldsets etc. around those fields to style them.

Put this in your Form and replace the {nested_resource} and {resource} tags with the name of your resources:

```
= form.fields_for :{nested_resource}s, {resource}.{nested_resource}s do |builder|
  = render '{nested_resource}_fields', fields: builder
= link_to_add_fields form, :{nested_resource}s, name: "Add Entry"
```

You can pass a css classes string as an optional fourth parameter to the link helper methods
```
= link_to_add_fields form, :{nested_resource}s, {options}
```
options:
```
{name: "", class: "", partial: ""}
```

and
```
= link_to_delete_fields fields, {options}
```
options:
```
{name: "", class: ""}
```

To add global custom css classes to the add and delete buttons just add an initializer called "dynamic_fields_for_rails.rb" and paste in the following to add your custom global classes:

```
# encoding: utf-8

DynamicFieldsForRails.setup do |config|
  config.delete_css_classes = ""
  config.add_css_classes = ""
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
