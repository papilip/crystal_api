require "./base_controller"
require "../json_messages"

abstract class CrystalApi::Controllers::JsonRestApiController < CrystalApi::Controllers::BaseController
  #include CrystalApi::Controllers::Utils

  getter :resource_name, :router

  def initialize(s)
    @service = s

    @actions = [
      "index",
      "show",
      "create",
      "update",
      "delete"
    ] of String

    @path = "/resources"

    # @router = {
    #   "GET /resources"        => "index",
    #   "GET /resources/:id"    => "show",
    #   "POST /resources"       => "create",
    #   "PUT /resources/:id"    => "update",
    #   "DELETE /resources/:id" => "delete",
    # }

    @resource_name = "resource"
  end

  def prepare_routes(route_handler : CrystalApi::RouteHandler)
    if @actions.includes?("index")
      route_handler.add_route("GET", @path) do |context|
        index(context)
      end
    end

    if @actions.includes?("show")
      route_handler.add_route("GET", @path + "/:id") do |context|
        show(context)
      end
    end
  end

  def index(context)
    context.set_json_headers
    service = @service as CrystalApi::CrystalService

    context.mark_time_pre_db
    collection = service.index
    context.mark_time_post_db

    response = collection.to_json
    context.set_time_cost_headers
    context.set_status_ok

    return response
  end

  def show(context)
    context.set_json_headers
    service = @service as CrystalApi::CrystalService

    context.mark_time_pre_db
    resource = service.show(context.params["id"])
    context.mark_time_post_db

    if resource
      context.set_status_ok
      context.set_time_cost_headers
      return resource.to_json
    else
      context.set_error_not_found
      return JsonMessages.not_found
    end
  end

  # curl -H "Content-Type: application/json" -X POST -d '{"event":{"name": "test1"}}' http://localhost:8001/events
  def create(req)
    service = @service as CrystalApi::CrystalService
    params = (JSON::Parser.new(req.body).parse) as Hash(String, JSON::Type)
    object_params = params[@resource_name] as Hash(String, JSON::Type)

    t = t_from
    resource = service.create(object_params)
    ts = t_diff(t)

    if resource
      response = ok(resource.to_json)
    else
      response = bad_request
    end

    add_time_cost_headers(response, ts)
    set_json_headers(response)
    return response
  end

  # curl -H "Content-Type: application/json" -X PUT -d '{"event":{"name": "test2"}}' http://localhost:8001/events/1
  def update(req)
    service = @service as CrystalApi::CrystalService
    params = (JSON::Parser.new(req.body).parse) as Hash(String, JSON::Type)
    object_params = params[@resource_name] as Hash(String, JSON::Type)
    db_id = req.params["id"]

    t = t_from
    resource = service.update(db_id, object_params)
    ts = t_diff(t)

    if resource
      response = ok(resource.to_json)
    else
      response = not_found
    end

    add_time_cost_headers(response, ts)
    set_json_headers(response)
    return response
  end

  # curl -H "Content-Type: application/json" -X DELETE http://localhost:8001/events/1
  def delete(req)
    service = @service as CrystalApi::CrystalService

    t = t_from
    resource = service.delete(req.params["id"])
    ts = t_diff(t)

    if resource
      response = ok(resource.to_json)
    else
      response = not_found
    end

    add_time_cost_headers(response, ts)
    set_json_headers(response)
    return response
  end
end