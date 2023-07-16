local ffi = require("ffi")

ffi.cdef [[
typedef void *PVOID;
typedef PVOID HANDLE;
typedef HANDLE HWND;
typedef unsigned long DWORD, *PDWORD, *LPDWORD;
typedef uint32_t UINT32;
typedef uint32_t POINTER_FLAGS;
typedef DWORD POINTER_INPUT_TYPE;
typedef long LONG;
typedef int32_t INT32;
typedef uint64_t UINT64;
typedef uint32_t POINTER_BUTTON_CHANGE_TYPE;
typedef UINT32 POINTER_FLAGS;
typedef UINT32 TOUCH_FLAGS;
typedef UINT32 TOUCH_MASK;
typedef UINT32 PEN_FLAGS;
typedef UINT32 PEN_MASK;
typedef int BOOL;

typedef enum tagPOINTER_BUTTON_CHANGE_TYPE {
    POINTER_CHANGE_NONE,
    POINTER_CHANGE_FIRSTBUTTON_DOWN,
    POINTER_CHANGE_FIRSTBUTTON_UP,
    POINTER_CHANGE_SECONDBUTTON_DOWN,
    POINTER_CHANGE_SECONDBUTTON_UP,
    POINTER_CHANGE_THIRDBUTTON_DOWN,
    POINTER_CHANGE_THIRDBUTTON_UP,
    POINTER_CHANGE_FOURTHBUTTON_DOWN,
    POINTER_CHANGE_FOURTHBUTTON_UP,
    POINTER_CHANGE_FIFTHBUTTON_DOWN,
    POINTER_CHANGE_FIFTHBUTTON_UP
  } POINTER_BUTTON_CHANGE_TYPE;

typedef struct tagPOINT {
    LONG x;
    LONG y;
  } POINT, *PPOINT, *NPPOINT, *LPPOINT;

typedef struct tagPOINTER_INFO {
    POINTER_INPUT_TYPE         pointerType;
    UINT32                     pointerId;
    UINT32                     frameId;
    POINTER_FLAGS              pointerFlags;
    HANDLE                     sourceDevice;
    HWND                       hwndTarget;
    POINT                      ptPixelLocation;
    POINT                      ptHimetricLocation;
    POINT                      ptPixelLocationRaw;
    POINT                      ptHimetricLocationRaw;
    DWORD                      dwTime;
    UINT32                     historyCount;
    INT32                      InputData;
    DWORD                      dwKeyStates;
    UINT64                     PerformanceCount;
    POINTER_BUTTON_CHANGE_TYPE ButtonChangeType;
  } POINTER_INFO;

typedef struct tagPOINTER_PEN_INFO {
    POINTER_INFO pointerInfo;
    PEN_FLAGS    penFlags;
    PEN_MASK     penMask;
    UINT32       pressure;
    UINT32       rotation;
    INT32        tiltX;
    INT32        tiltY;
} POINTER_PEN_INFO;

BOOL GetPointerFramePenInfoHistory (UINT32 pointerId, UINT32 *entriesCount, UINT32 *pointerCount, POINTER_PEN_INFO *penInfo);

BOOL ScreenToClient(HWND hWnd, LPPOINT lpPoint);
]]

local user32 = ffi.load("user32")
local maxEntries = 100
local pointerInfo = ffi.new("POINTER_PEN_INFO[?]", maxEntries)
local entriesCount = ffi.new("uint32_t[1]", 1)
local pointerCount = ffi.new("uint32_t[1]", 1)
local getPointerFramePenInfoHistory = ffi.C.GetPointerFramePenInfoHistory
local ScreenToClient = ffi.C.ScreenToClient

local function read_pen_history(id,callback)
    if type(id) ~= "userdata" then
        return nil
    end
    id = ffi.cast("UINT32", id)
    -- I am not really sure what entriesCount and pointerCount exactly about,
    -- but I assume that pointerCount is for multitouch?
    entriesCount[0] = maxEntries
    pointerCount[0] = 1
    local result = getPointerFramePenInfoHistory(id or 0, entriesCount, pointerCount, pointerInfo)
    if result == 0 then
        return nil
    end
    local entries = {}
    if result == 1 then
        local offset = 0
        for pointer=0, pointerCount[0] - 1 do
            for entry=0, entriesCount[0] - 1 do
                local penInfo = pointerInfo[offset]
                local ptPixelLocation = penInfo.pointerInfo.ptPixelLocation
                ScreenToClient(penInfo.pointerInfo.hwndTarget, ptPixelLocation)
                entries[#entries+1] = {penInfo.pressure / 1024, ptPixelLocation.x, ptPixelLocation.y,#entries+1}
                offset = offset + 1
                if offset >= maxEntries then
                    goto callback
                end
            end
        end
        ::callback::
        if callback then
            for i=#entries,1,-1 do
               callback(unpack(entries[i]))
            end
        end
    end
    return entries
end

return read_pen_history
