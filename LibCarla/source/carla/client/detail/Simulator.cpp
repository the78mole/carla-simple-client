// Copyright (c) 2017 Computer Vision Center (CVC) at the Universitat Autonoma
// de Barcelona (UAB).
//
// This work is licensed under the terms of the MIT license.
// For a copy, see <https://opensource.org/licenses/MIT\>.

#include "carla/client/detail/Simulator.h"

#include "carla/Debug.h"
#include "carla/Exception.h"
#include "carla/Logging.h"
#include "carla/client/BlueprintLibrary.h"
#include "carla/client/Map.h"
#include "carla/client/Sensor.h"
#include "carla/client/TimeoutException.h"
#include "carla/client/detail/ActorFactory.h"
#include "carla/client/detail/Episode.h"
#include "carla/client/detail/WalkerNavigation.h"

#include <exception>

using namespace std::string_literals;

namespace carla {
namespace client {
namespace detail {

  // ===========================================================================
  // -- Constructor ------------------------------------------------------------
  // ===========================================================================

  Simulator::Simulator(
      const std::string &host,
      const uint16_t port,
      const size_t worker_threads,
      const bool enable_garbage_collection)
    : _client(host, port, worker_threads),
      _light_manager(new LightManager()),
      _gc_policy(enable_garbage_collection ?
        GarbageCollectionPolicy::Enabled : GarbageCollectionPolicy::Disabled) {}

  // ===========================================================================
  // -- Access to global objects in the episode --------------------------------
  // ===========================================================================

  SharedPtr<BlueprintLibrary> Simulator::GetBlueprintLibrary() {
    auto defs = _client.GetActorDefinitions();
    return MakeShared<BlueprintLibrary>(std::move(defs));
  }

  rpc::VehicleLightStateList Simulator::GetVehiclesLightStates() {
    return _client.GetVehiclesLightStates();
  }

  SharedPtr<Actor> Simulator::GetSpectator() {
    return MakeActor(_client.GetSpectator());
  }

  uint64_t Simulator::SetEpisodeSettings(const rpc::EpisodeSettings &settings) {
    return _client.SetEpisodeSettings(settings);
  }

  // ===========================================================================
  // -- Episode management -----------------------------------------------------
  // ===========================================================================

  void Simulator::GetReadyCurrentEpisode() {
    if (_episode == nullptr) {
      _episode = std::make_shared<Episode>(_client, std::weak_ptr<Simulator>(shared_from_this()));
      _episode->Listen();
      _light_manager->SetEpisode(WeakEpisodeProxy{shared_from_this()});
    }
  }

  EpisodeProxy Simulator::GetCurrentEpisode() {
    GetReadyCurrentEpisode();
    return EpisodeProxy{shared_from_this()};
  }

  SharedPtr<Map> Simulator::GetCurrentMap() {
    DEBUG_ASSERT(_episode != nullptr);
    if (_cached_map == nullptr) {
      _cached_map = MakeShared<Map>(_client.GetMapInfo(), _client.GetMapData());
    }
    return _cached_map;
  }

  // ===========================================================================
  // -- Actor management -------------------------------------------------------
  // ===========================================================================

  SharedPtr<Actor> Simulator::SpawnActor(
      const ActorBlueprint &blueprint,
      const geom::Transform &transform,
      Actor *parent,
      rpc::AttachmentType attachment_type,
      GarbageCollectionPolicy gc,
      const std::string &socket_name) {
    rpc::Actor actor;
    if (parent != nullptr) {
      actor = _client.SpawnActorWithParent(
          blueprint.MakeActorDescription(),
          transform,
          parent->GetId(),
          attachment_type,
          socket_name);
    } else {
      actor = _client.SpawnActor(blueprint.MakeActorDescription(), transform);
    }
    
    const auto gca = (gc == GarbageCollectionPolicy::Inherit ? _gc_policy : gc);
    DEBUG_ASSERT(actor.id != 0u);
    
    if (_episode == nullptr) {
      GetReadyCurrentEpisode();
    }
    
    return ActorFactory::MakeActor(
        GetCurrentEpisode(),
        std::move(actor),
        gca);
  }

  bool Simulator::DestroyActor(Actor &actor) {
    bool success = _client.DestroyActor(actor.GetId());
    // Note: EpisodeState removal happens automatically through episode updates
    return success;
  }

  // ===========================================================================
  // -- Traffic management -----------------------------------------------------
  // ===========================================================================

  void Simulator::FreezeAllTrafficLights(bool frozen) {
    _client.FreezeAllTrafficLights(frozen);
  }

  // ===========================================================================
  // -- Sensor operations ------------------------------------------------------
  // ===========================================================================

  void Simulator::SubscribeToSensor(
      const Sensor &sensor,
      std::function<void(SharedPtr<sensor::SensorData>)> callback) {
    // Stub - sensor streaming not implemented in simplified version
    // In full version, this would subscribe to the streaming server
  }

  void Simulator::UnSubscribeFromSensor(Actor &sensor) {
    // Stub - sensor streaming not implemented in simplified version
  }

  void Simulator::EnableGBuffers(const Sensor &sensor, bool enabled) {
    // Stub - GBuffer support not implemented in simplified version
  }

  void Simulator::SubscribeToGBuffer(
      Actor &sensor,
      uint32_t gbuffer_id,
      std::function<void(SharedPtr<sensor::SensorData>)> callback) {
    // Stub - GBuffer support not implemented in simplified version
  }

  void Simulator::UnSubscribeFromGBuffer(Actor &sensor, uint32_t gbuffer_id) {
    // Stub - GBuffer support not implemented in simplified version
  }

  void Simulator::EnableForROS(const Sensor &sensor) {
    // Stub - ROS support not implemented in simplified version
  }

  void Simulator::DisableForROS(const Sensor &sensor) {
    // Stub - ROS support not implemented in simplified version
  }

  bool Simulator::IsEnabledForROS(const Sensor &sensor) {
    return false; // Stub
  }

  void Simulator::Send(const Sensor &sensor, std::string message) {
    // Stub - sensor messaging not implemented in simplified version
  }

  void Simulator::SetIgnoredVehicles(const Sensor &sensor, const std::vector<ActorId> &ids) {
    // Stub - not implemented in simplified version
  }

  // ===========================================================================
  // -- File/Cache operations --------------------------------------------------
  // ===========================================================================

  std::vector<std::string> Simulator::GetRequiredFiles(const std::string &folder, const bool download) const {
    return _client.GetRequiredFiles(folder, download);
  }

  std::vector<uint8_t> Simulator::GetCacheFile(const std::string &name, const bool request_otherwise) const {
    return _client.GetCacheFile(name, request_otherwise);
  }

  // ===========================================================================
  // -- Texture operations -----------------------------------------------------
  // ===========================================================================

  void Simulator::ApplyColorTextureToObjects(
      const std::vector<std::string> &objects_name,
      const rpc::MaterialParameter &parameter,
      const rpc::TextureColor &Texture) {
    _client.ApplyColorTextureToObjects(objects_name, parameter, Texture);
  }

  void Simulator::ApplyColorTextureToObjects(
      const std::vector<std::string> &objects_name,
      const rpc::MaterialParameter &parameter,
      const rpc::TextureFloatColor &Texture) {
    _client.ApplyColorTextureToObjects(objects_name, parameter, Texture);
  }

  // ===========================================================================
  // -- Tick operations --------------------------------------------------------
  // ===========================================================================

  WorldSnapshot Simulator::WaitForTick(time_duration timeout) {
    // Stub - would need full Episode implementation
    throw_exception(std::runtime_error("WaitForTick not implemented in minimal client"));
  }

  uint64_t Simulator::Tick(time_duration timeout) {
    // Stub - would need full Episode implementation  
    throw_exception(std::runtime_error("Tick not implemented in minimal client"));
  }

  // ===========================================================================
  // -- Pedestrian/Navigation operations ---------------------------------------
  // ===========================================================================

  boost::optional<geom::Location> Simulator::GetRandomLocationFromNavigation() {
    return {}; // Stub - navigation not implemented
  }

  void Simulator::SetPedestriansCrossFactor(float percentage) {
    // Stub - pedestrian AI not implemented
  }

  void Simulator::SetPedestriansSeed(unsigned int seed) {
    // Stub - pedestrian AI not implemented
  }

  // ===========================================================================
  // -- Misc operations --------------------------------------------------------
  // ===========================================================================

  std::vector<std::string> Simulator::GetNamesOfAllObjects() const {
    return _client.GetNamesOfAllObjects();
  }

} // namespace detail
} // namespace client
} // namespace carla
