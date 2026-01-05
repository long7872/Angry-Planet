# 2.9 Thiết kế các hệ thống game chính

Hệ thống nhân vật chịu trách nhiệm quản lý các thuộc tính và hành vi cơ bản của người chơi, bao gồm vị trí, trạng thái di chuyển, animation và tương tác với các công trình trong game. Nhân vật được triển khai theo mô hình entity-component của Flame engine, trong đó các chức năng như di chuyển, input handling và hiển thị được tách thành các component riêng biệt. Thiết kế này giúp hệ thống linh hoạt, dễ bảo trì và cho phép mở rộng thêm các trạng thái hoặc cơ chế tương tác mới mà không ảnh hưởng đến cấu trúc tổng thể. Trong môi trường multiplayer, vị trí và trạng thái animation của nhân vật được gửi đến server và broadcast tới các client khác để đảm bảo đồng bộ hóa.

## 2.9.1 Thiết kế hệ thống nhân vật

Hệ thống nhân vật chịu trách nhiệm quản lý vị trí, trạng thái di chuyển, animation và tương tác với các công trình. Thiết kế dựa trên mô hình component của Flame engine, giúp mở rộng dễ dàng, ví dụ thêm các trạng thái mới, loại nhân vật khác hoặc các cơ chế gameplay bổ sung trong tương lai.

### 2.9.1.1 State machine di chuyển

Hành vi di chuyển của nhân vật được quản lý thông qua một state machine đơn giản với hai trạng thái chính: **Idle** và **Running**. Mỗi trạng thái kết hợp với bốn hướng di chuyển (**Down**, **Right**, **Left**, **Up**) tạo thành tổng cộng 8 trạng thái animation khác nhau.

Việc chuyển đổi giữa các state được kích hoạt bởi input từ joystick:
- Khi joystick không có input (delta = 0), nhân vật chuyển sang trạng thái **Idle**
- Khi joystick có input, nhân vật chuyển sang trạng thái **Running** và hướng được xác định dựa trên vector di chuyển

Hướng di chuyển được tính toán như sau:
- Nếu `|velocity.x| > |velocity.y|`: hướng ngang (Right nếu x > 0, Left nếu x < 0)
- Ngược lại: hướng dọc (Down nếu y > 0, Up nếu y < 0)

State machine giúp tách biệt rõ ràng logic xử lý hành vi và hiển thị. Client gửi thông tin vị trí và trạng thái của nhân vật đến server với tần suất 60 lần/giây (mỗi ~16.67ms). Server nhận và broadcast thông tin này đến tất cả client khác để đồng bộ hóa vị trí và animation của các remote players, mang lại trải nghiệm multiplayer mượt mà.

### 2.9.1.2 Di chuyển và input handling

Hệ thống di chuyển nhân vật được điều khiển bởi **PlayerInputHandler**, component xử lý input từ joystick ảo trên màn hình. Mỗi frame, handler đọc giá trị delta từ joystick (vector chuẩn hóa trong khoảng [-1, 1]) và áp dụng tốc độ di chuyển (speed = 100 pixels/giây) để tính toán velocity.

Nhân vật di chuyển tự do trong thế giới game mà không bị chặn bởi terrain hoặc các công trình. Vị trí được cập nhật dựa trên công thức:
```
position += velocity × deltaTime
```

Trong môi trường multiplayer, mỗi client quản lý vị trí local player độc lập, sau đó gửi position update đến server. Server broadcast thông tin vị trí của tất cả players để các client khác có thể render **RemotePlayerComponent** tương ứng. Cơ chế này đảm bảo mỗi người chơi có thể thấy vị trí và animation của người chơi khác trong thời gian thực.

### 2.9.1.3 Animation system

Animation system sử dụng sprite sheet với kích thước 32×32 pixels cho mỗi frame. Toàn bộ animation được lưu trong một file sprite duy nhất (`ui/player.png`) với cấu trúc 6 hàng × 6 cột:
- **Hàng 0-3**: Idle animation cho 4 hướng (down, right, left, up)
- **Hàng 4-5**: Running animation (chỉ cần 2 hàng vì animation được mirror cho trái/phải)
- Mỗi animation có 6 frames với thời gian 0.1 giây/frame

Khi load game, hệ thống tạo các **SpriteAnimation** cho mỗi tổ hợp state-direction và lưu vào map:
```
animations[PlayerState][PlayerDirection] → SpriteAnimation
```

Mỗi frame update, hệ thống:
1. Kiểm tra state và direction hiện tại dựa trên velocity
2. Nếu state hoặc direction thay đổi, chuyển sang animation ticker tương ứng
3. Cập nhật animation ticker với deltaTime để tiến frame

Animation được chọn và render độc lập ở mỗi client dựa trên state message nhận được từ server. Điều này đảm bảo tất cả người chơi nhìn thấy animation đồng bộ cho cùng một nhân vật. Hệ thống animation hiện tại tập trung vào di chuyển cơ bản; các hiệu ứng đặc biệt như building animation, harvesting effects hoặc particle effects chưa được triển khai trong phiên bản hiện tại.

## 2.9.2 Thiết kế hệ thống bản đồ

Bản đồ là môi trường chính của game, chịu trách nhiệm lưu trữ thông tin terrain, tài nguyên và cung cấp dữ liệu cho việc render và placement validation. Thiết kế bản đồ dựa trên grid system để quản lý vị trí, render hiệu quả và logic xây dựng công trình.

### 2.9.2.1 Grid system

Hệ thống grid chia bản đồ thành các **chunk** có kích thước cố định 32×32 tiles. Mỗi tile có kích thước 16×16 pixels, do đó mỗi chunk chiếm 512×512 pixels trong world space.

Grid system hoạt động như sau:
- **Chunk coordinates**: Vị trí chunk được tính bằng `(worldX / 512, worldY / 512)`
- **Tile coordinates**: Vị trí tile trong chunk `(0-31, 0-31)`
- **World coordinates**: Vị trí pixel thực tế trong thế giới game

Chunk được generate bởi server khi client request thông qua message `get_chunk` với tọa độ chunk. Server sử dụng **WorldManager** để generate hoặc lấy chunk từ cache, sau đó gửi về client qua message `chunk_data`.

Client quản lý dynamic chunk loading thông qua **ChunkLoader** component, tự động request các chunk trong vùng view distance (5×5 chunks xung quanh player) với interval check 0.5 giây. Chunks đã load được lưu trong **ClientWorld** dưới dạng **ChunkRenderer** components để hiển thị.

Grid system không lưu trữ thông tin về occupancy (công trình chiếm chỗ) hoặc pathfinding. Placement validation được thực hiện bởi **PlacementStateManager** dựa trên tile data và **MachineRegistry**.

### 2.9.2.2 Tile types và properties

Hệ thống bản đồ sử dụng biome-based terrain classification với 5 loại biome được xác định theo độ cao (height value từ Perlin noise):

1. **Water** (height < 0.4): Vùng nước
2. **Sand** (0.4 ≤ height < 0.5): Bãi cát ven biển
3. **Grass** (0.5 ≤ height < 0.7): Đồng cỏ
4. **Tree** (0.7 ≤ height < 0.85): Rừng cây
5. **Stone** (height ≥ 0.85): Vùng đá núi

Mỗi tile được biểu diễn bởi **TileData** với các thuộc tính:
- **biome**: Loại biome (BiomeType enum)
- **resource**: Loại tài nguyên có thể khai thác (ResourceType enum)
- **state**: Trạng thái của resource node (ResourceState - damaged/depleted states)

**Resource types** bao gồm:
- **Wood**: Từ biome Tree (rừng cây)
- **Coal, Iron, EnergyCatalyst**: Từ các mỏ quặng được sinh ra ngẫu nhiên dựa trên detail noise

Tile properties được lưu trực tiếp trong Chunk data structure dưới dạng array 1024 phần tử (32×32). Hệ thống không lưu các thuộc tính như `passable`, `pollution_modifier`, hoặc `collision` vì nhân vật di chuyển tự do và pollution được quản lý riêng bởi **PollutionSystem**.

Rendering sử dụng **autotile system** để tạo transitions mượt mà giữa các biome. Hệ thống sử dụng bitmask để xác định sprite phù hợp dựa trên các biome lân cận, tạo hiệu ứng blend tự nhiên giữa water-sand, sand-grass, grass-tree, tree-stone.

### 2.9.2.3 Resource generation logic

Tài nguyên được generate cố định trong quá trình world generation, không phải spawn ngẫu nhiên runtime. Server sử dụng **NoiseGenerator** với Perlin noise để tạo thế giới deterministic, có nghĩa là cùng một chunk coordinates sẽ luôn generate ra cùng một terrain và resource layout.

Logic generation hoạt động như sau:

**Bước 1: Generate height và detail noise**
- **Height noise**: Xác định biome type tại mỗi tile
- **Detail noise**: Xác định xem có spawn resource tại vị trí đó không và loại resource nào

**Bước 2: Classify biome**
Dựa trên height value, **BiomeClassifier** xác định biome type theo các ngưỡng đã định nghĩa.

**Bước 3: Edge detection**
Hệ thống kiểm tra các tile lân cận để phát hiện biome edge. Nếu tile nằm ở ranh giới giữa 2 biome khác nhau, resource sẽ **không được spawn** để tránh visual conflicts với autotile transitions.

**Bước 4: Resource assignment**
Nếu tile không nằm ở edge, **BiomeClassifier.getResource()** sử dụng detail noise để quyết định:
- Biome **Tree** → có thể spawn Wood
- Biome **Stone/Grass** → có thể spawn Coal, Iron, hoặc EnergyCatalyst dựa trên detail value ranges
- Các biome khác → không spawn resource

Tài nguyên **không respawn** sau khi bị khai thác hết. Khi player sử dụng **DiggerMachine** hoặc **ChopperMachine** để extract resource, resource state có thể chuyển sang damaged hoặc depleted, nhưng không có cơ chế regeneration.

Server cache các chunks đã generate trong memory để tránh regenerate mỗi khi client request. Chunk data được serialize và gửi qua WebSocket message dưới dạng JSON.

## 2.9.3 Thiết kế hệ thống xây dựng

Hệ thống xây dựng là trung tâm của gameplay, cho phép người chơi triển khai các công trình (machines), quản lý sản xuất và tối ưu hóa dây chuyền tự động. Hệ thống này tích hợp placement validation, input/output inventory management, và logic tự động vận hành theo tick.

### 2.9.3.1 Building placement validation

Khi người chơi chọn đặt một công trình, hệ thống thực hiện kiểm tra hợp lệ hoàn toàn ở **client-side** thông qua **PlacementStateManager**. Quá trình validation diễn ra qua nhiều bước:

**Bước 1: Mở inventory và chọn machine**
- Player mở inventory overlay để xem danh sách machines có thể build
- Hệ thống kiểm tra **build cost** và so sánh với inventory hiện tại
- Nếu không đủ tài nguyên, machine sẽ hiển thị màu xám (disabled) và không thể select

**Bước 2: Hiển thị valid placement tiles**
- Khi player chọn một machine, **PlacementStateManager** chuyển sang state `itemSelected`
- Hệ thống highlight tất cả các tile trong vùng 7×7 xung quanh player (radius = 3 tiles)
- Mỗi tile được kiểm tra với 3 điều kiện:
  1. **Chunk loaded**: Tile data phải có sẵn (chunk đã được request và receive)
  2. **No existing machine**: **MachineRegistry** xác nhận không có machine nào tại vị trí đó
  3. **Resource type match**: Tile resource phải nằm trong `validPlacements` của machine

**Valid placement rules cho từng machine type:**
- **Digger**: Chỉ đặt được **trên** tiles có resource (Coal, Iron, hoặc EnergyCatalyst)
- **Chopper**: Chỉ đặt được **trên** tiles có Wood (biome Tree)
- **Burner, Smelter, Holder, Greener, Linkers**: Đặt được trên bất kỳ tile nào có `ResourceType.none`

Tiles hợp lệ hiển thị **TileHighlighter** màu xanh lá; tiles không hợp lệ hiển thị màu đỏ.

**Bước 3: Select tile và ghost preview**
- Player tap vào một valid tile (màu xanh)
- Hệ thống chuyển sang state `ghostPreview`, hiển thị:
  - **GhostPreview** component: Sprite của machine với opacity thấp tại vị trí tile
  - **ConfirmButtons** overlay: Nút confirm (checkmark) và cancel (X)

Nếu player tap vào invalid tile hoặc ngoài vùng highlight, hệ thống hiển thị out-of-range effect và không chuyển state.

**Bước 4: Confirm placement**
- Khi player tap nút confirm, hệ thống thực hiện final validation:
  1. Kiểm tra lại affordability (đề phòng inventory thay đổi trong lúc preview)
  2. Deduct build cost từ inventory thông qua `inventory.deductCost()`
  3. Lấy resource node tại tile (nếu có) để bind với machine

- **MachineFactory** tạo machine instance tương ứng:
  ```dart
  machine = MachineFactory.createMachine(
    type: selectedMachine,
    tilePosition: selectedTile,
    game: game,
    resourceNode: tile.resource,  // For DiggerMachine/ChopperMachine
  )
  ```

- Machine được add vào world và register với các hệ thống:
  - **World.add(machine)**: Add component vào Flame rendering tree
  - **MachineRegistry.registerMachine()**: Lưu vị trí để ngăn placement chồng lấn
  - **GameManager.registerMachine()**: Tạo EnergyNode và đăng ký với EnergyNetwork và PollutionSystem

Toàn bộ quá trình placement validation và execution diễn ra ở **client-side**. Server không tham gia validate hay xác nhận placements. Điều này phù hợp với kiến trúc hiện tại vì game logic chủ yếu chạy trên client, còn server chỉ quản lý world generation và player position synchronization.

### 2.9.3.2 Automation logic flow

Các công trình tự động vận hành theo cơ chế **tick-based**, với tần suất chính xác **1 tick/giây** được quản lý bởi **GameTick** component. Mỗi tick, **GameManager** điều phối các hệ thống game theo thứ tự:

**Tick flow:**
```
1. EnergyNetwork.tick()         → Tính toán energy production/consumption stats
2. MachineRegistry.tickAllMachines() → Gọi tick() cho tất cả machines
3. PollutionSystem.tick()       → Cập nhật pollution levels
```

**Machine operation cycle (mỗi tick):**

Mỗi machine kế thừa từ **BaseMachine** và override method `operate()` để triển khai logic riêng. Trước khi gọi operate(), base class thực hiện:

**Bước 1: Update power status**
```dart
_updatePowerStatus() {
  if (stats.isGenerator) {
    // Generator tự set power state trong operate()
  } else {
    // Consumer is powered nếu có energy trong buffer
    isPowered = storedEnergy > 0
  }
}
```

**Bước 2: Execute operate() logic**

Ví dụ **DiggerMachine**:
1. Kiểm tra điều kiện hoạt động:
   - `canOperate()`: Kiểm tra có đủ năng lượng trong buffer
   - Output storage chưa đầy (< storageCapacity)
2. Nếu hợp lệ, `consumeEnergy()` trừ năng lượng từ buffer
3. Tăng `extractionProgress` (1 giây mỗi tick)
4. Khi progress đạt `extractionTime` (5 giây), add 1 item vào output storage và reset progress

Ví dụ **BurnerMachine** (Generator):
1. Nếu đang cháy (`isBurning`):
   - Giảm `burnTimeRemaining` (1 giây/tick)
   - Generate năng lượng vào buffer: `storedEnergy += energyPerSecond`
   - Clamp theo `maxStoredEnergy`
2. Nếu hết fuel:
   - Set `isBurning = false`, `isPowered = false`
3. Nếu không cháy, kiểm tra input storage:
   - Nếu có Coal → burn 10 giây, generate 20 NE/s
   - Nếu có Wood → burn 2 giây, generate 20 NE/s
   - Consume 1 fuel item từ input storage

Ví dụ **SmelterMachine** (Processor):
1. Nếu đang processing:
   - Consume energy mỗi tick
   - Tăng `processingProgress`
   - Khi đạt `processingTime`, add output vào output storage
2. Nếu không processing:
   - Kiểm tra `selectedRecipe` có đủ inputs trong input storage
   - Kiểm tra output storage còn chỗ
   - Consume inputs, bắt đầu processing cycle

**Energy distribution:**

Năng lượng được phân phối qua **EnergyLinkerMachine**:
1. **Pull energy** từ source machine's buffer vào linker's buffer (50 NE/tick)
2. **Distribute energy** từ linker's buffer ra target machines (chia đều cho tối đa 4 targets)
3. Linker tự consume 5 NE/s cho hoạt động

Machines **không tự động transfer items** giữa nhau. Player phải manually:
- Lấy items từ machine output storage
- Đưa items vào machine input storage

Hệ thống không có **Conveyor belts** để tự động vận chuyển items. Automation chỉ giới hạn ở việc machines tự hoạt động khi có đủ energy và inputs, không bao gồm item logistics.

### 2.9.3.3 Resource flow và recipe system

Mối quan hệ giữa các công trình và tài nguyên được định nghĩa thông qua **Recipe system**, không phải dependency graph. Recipe system hoạt động theo mô hình đơn giản:

**Recipe structure:**
```dart
class Recipe {
  List<RecipeInput> inputs;      // Nguyên liệu cần
  ResourceType output;           // Sản phẩm
  int outputAmount;              // Số lượng output
  double processingTime;         // Thời gian xử lý (giây)
}

class RecipeInput {
  ResourceType resource;
  int amount;
}
```

**Các recipes chính:**

1. **Iron Ore → Iron Bar** (Smelter)
   - Input: 2 Iron
   - Output: 1 Iron Bar
   - Time: 5 seconds

2. **Energy Catalyst → Energy Cube** (Smelter)
   - Input: varies
   - Output: 1 Energy Cube
   - Time: 5 seconds

Recipes được hardcode trong machine logic và chỉ áp dụng cho **SmelterMachine**. Player có thể select recipe thông qua machine UI, và smelter chỉ accept inputs tương ứng với selected recipe.

**Resource flow patterns:**

Flow thực tế trong game:
```
1. Extraction:
   DiggerMachine (on Iron node) → Iron Ore output
   ChopperMachine (on Wood tile) → Wood output

2. Energy generation:
   BurnerMachine input (Coal/Wood) → Energy buffer

3. Processing:
   SmelterMachine input (Iron Ore) → Iron Bar output

4. Energy distribution:
   BurnerMachine buffer → EnergyLinkerMachine buffer → Consumer machines
```

**Không có dependency graph implementation:**

Hệ thống không triển khai:
- **Directed acyclic graph** cho production chains
- **Server-side optimization** calculations
- **Visual flow diagrams** cho production lines
- **Deadlock detection** algorithms
- **Automatic input/output connections**

Resource flow hoàn toàn manual, phụ thuộc vào player:
- Di chuyển items từ machine output → inventory → machine input
- Thiết lập energy linker connections thông qua UI
- Monitor production bottlenecks bằng cách kiểm tra machine storages

Machine inventory management được xử lý bởi **Inventory** class với stack-based system:
- Mỗi machine có **inputStorage** và **outputStorage** riêng
- Storage capacity được define trong **MachineStats** (thường 10-20 items)
- Items được lưu dưới dạng **ItemStack** với resource type và quantity

Player tương tác với machine storage thông qua **MachineUIOverlay**, có thể:
- View input/output contents
- Transfer items giữa player inventory và machine storage
- Select recipes (cho Smelter)
- Configure energy linker connections

Hệ thống này ưu tiên sự đơn giản và player control hơn là automation phức tạp, phù hợp với scope hiện tại của game.

---

## Tóm tắt các điểm khác biệt chính so với implementation thực tế:

**Hệ thống nhân vật:**
- ✅ Có: State machine với Idle/Running, 4 directions, animation system, position sync
- ❌ Không có: Walking/Interacting states, collision system, năng lượng/máu cho player, particle effects

**Hệ thống bản đồ:**
- ✅ Có: Grid/chunk system, 5 biome types, resource generation theo noise
- ❌ Không có: Tile properties như passable/collision, respawn system, proximity rules cho spawn

**Hệ thống xây dựng:**
- ✅ Có: Placement validation, tick-based automation, recipe system, energy network
- ❌ Không có: Server authority, Conveyor belts, automatic item transfer, dependency graph, deadlock detection
