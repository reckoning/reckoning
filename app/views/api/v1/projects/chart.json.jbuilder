# frozen_string_literal: true

json.labels @chart[:labels]
json.datasets @chart[:datasets] do |dataset|
  json.name dataset[:name]
  json.color dataset[:color]
  json.data dataset[:data]
  json.zone dataset[:zone]
end
json.budget @chart[:budget]
json.ticks @chart[:ticks]
