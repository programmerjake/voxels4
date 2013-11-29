/*
 * Voxels is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Voxels is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Voxels; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */
module resource.texture_atlas;
import render.texture_descriptor;
import image;

public class TextureAtlas
{
	private immutable float minU, maxU, minV, maxV;
	public immutable int left, top, width, height;
	public static immutable int textureXRes = 512, textureYRes = 256;
	private static Image textureInternal = null;
	package this(int left, int top, int width, int height)
	{
        this.left = left;
		this.top = top;
        this.width = width;
        this.height = height;
        immutable float offset = 0.1f;
        minU = (left + offset) / textureXRes;
        maxU = (left + width - offset) / textureXRes;
        minV = 1 - (top + height - offset) / textureYRes;
        maxV = 1 - (top + offset) / textureYRes;
	}
	public TextureDescriptor opCast(T : TextureDescriptor)() const
	{
		return td;
	}
	public @property TextureDescriptor td() const
	{
		return TextureDescriptor(texture, minU, maxU, minV, maxV);
	}
	public static @property Image texture()
	{
		if(textureInternal is null)
		{
			textureInternal = new Image("textures.png");
		}
		return textureInternal;
	}
	public static immutable TextureAtlas
	ActivatorRailOff,
    ActivatorRailOn,
    BedHead,
    BedFoot,
    BedTopSide,
    BedTopLeftSide,
    BedTopRightSide,
    BedBottom,
    BedBottomLeftSide,
    BedBottomRightSide,
    BedBottomSide,
    BedItem,
    Font8x8,
    Shockwave,
    Bedrock,
    BirchLeaves,
    BirchPlank,
    BirchSapling,
    BirchWood,
    WoodEnd,
    BlazePowder,
    BlazeRod,
    Bone,
    BoneMeal,
    Bow,
    BrownMushroom,
    Bucket,
    CactusSide,
    CactusBottom,
    CactusTop,
    CactusGreen,
    ChestSide,
    ChestTop,
    ChestFront,
    CobbleStone,
    Coal,
    CoalOre,
    CocoaSmallSide,
    CocoaSmallTop,
    CocoaSmallStem,
    CocoaMediumSide,
    CocoaMediumTop,
    CocoaMediumStem,
    CocoaLargeSide,
    CocoaLargeTop,
    CocoaLargeStem,
    CocoaBeans,
    DeadBush,
    DandelionYellow,
    Dandelion,
    CyanDye,
    Delete0,
    Delete1,
    Delete2,
    Delete3,
    Delete4,
    Delete5,
    Delete6,
    Delete7,
    Delete8,
    Delete9,
    DetectorRailOff,
    DetectorRailOn,
    Diamond,
    DiamondAxe,
    DiamondHoe,
    DiamondOre,
    DiamondPickaxe,
    DiamondShovel,
    Dirt,
    DirtMask,
    DispenserSide,
    DispenserTop,
    DropperSide,
    DropperTop,
    DispenserDropperPistonFurnaceFrame,
    Emerald,
    EmeraldOre,
    PistonBaseSide,
    PistonBaseTop,
    PistonHeadSide,
    PistonHeadFace,
    PistonHeadBase,
    StickyPistonHeadFace,
    FarmlandSide,
    FarmlandTop,
    Fire0,
    Fire1,
    Fire2,
    Fire3,
    Fire4,
    Fire5,
    Fire6,
    Fire7,
    Flint,
    FlintAndSteel,
    FurnaceFrontOff,
    FurnaceSide,
    FurnaceFrontOn,
    WorkBenchTop,
    WorkBenchSide0,
    WorkBenchSide1,
    Glass,
    GoldAxe,
    GoldHoe,
    GoldIngot,
    GoldOre,
    GoldPickaxe,
    GoldShovel,
    GrassMask,
    GrassTop,
    Gravel,
    GrayDye,
    Gunpowder,
    HopperRim,
    HopperInside,
    HopperSide,
    HopperBigBottom,
    HopperMediumBottom,
    HopperSmallBottom,
    HopperItem,
    HotBarBox,
    InkSac,
    IronAxe,
    IronHoe,
    IronIngot,
    IronOre,
    IronPickaxe,
    IronShovel,
    JungleLeaves,
    JunglePlank,
    JungleSapling,
    JungleWood,
    Ladder,
    LapisLazuli,
    LapisLazuliOre,
    WheatItem,
    LavaBucket,
    OakLeaves,
    LeverBaseBigSide,
    LeverBaseSmallSide,
    LeverBaseTop,
    LeverHandleSide,
    LeverHandleTop,
    LeverHandleBottom,
    LightBlueDye,
    LightGrayDye,
    LimeDye,
    MagentaDye,
    MinecartInsideSide,
    MinecartInsideBottom,
    MinecartItem,
    MinecartOutsideLeftRight,
    MinecartOutsideFrontBack,
    MinecartOutsideBottom,
    MinecartOutsideTop,
    MinecartWithChest,
    MinecartWithHopper,
    MinecartWithTNT,
    MobSpawner,
    OrangeDye,
    WaterSide0,
    WaterSide1,
    WaterSide2,
    WaterSide3,
    WaterSide4,
    WaterSide5,
    Obsidian,
    ParticleSmoke0,
    ParticleSmoke1,
    ParticleSmoke2,
    ParticleSmoke3,
    ParticleSmoke4,
    ParticleSmoke5,
    ParticleSmoke6,
    ParticleSmoke7,
    ParticleFire0,
    ParticleFire1,
    PinkDye,
    PinkStone,
    PistonShaft,
    OakPlank,
    PoweredRailOff,
    PoweredRailOn,
    PurpleDye,
    PurplePortal,
    Quartz,
    Rail,
    RailCurve,
    RedMushroom,
    BlockOfRedstone,
    RedstoneComparatorOff,
    RedstoneComparatorOn,
    RedstoneComparatorRepeatorSide,
    RedstoneShortTorchSideOn,
    RedstoneShortTorchSideOff,
    RedstoneDust0,
    RedstoneDust1,
    RedstoneDust2Corner,
    RedstoneDust2Across,
    RedstoneDust3,
    RedstoneDust4,
    RedstoneDustItem,
    RedstoneRepeatorBarSide,
    RedstoneRepeatorBarTopBottom,
    RedstoneRepeatorBarEnd,
    RedstoneOre,
    ActiveRedstoneOre,
    RedstoneRepeatorOff,
    RedstoneRepeatorOn,
    RedstoneTorchSideOn,
    RedstoneTorchSideOff,
    RedstoneTorchTopOn,
    RedstoneTorchTopOff,
    RedstoneTorchBottomOn,
    RedstoneTorchBottomOff,
    Rose,
    RoseRed,
    Sand,
    OakSapling,
    WheatSeeds,
    Shears,
    Slime,
    Snow,
    SnowBall,
    SnowGrass,
    SpruceLeaves,
    SprucePlank,
    SpruceSapling,
    SpruceWood,
    Stick,
    Stone,
    StoneAxe,
    StoneButtonFace,
    StoneButtonLongEdge,
    StoneButtonShortEdge,
    WoodButtonFace,
    WoodButtonLongEdge,
    WoodButtonShortEdge,
    StoneHoe,
    StonePickaxe,
    StonePressurePlateFace,
    StonePressurePlateSide,
    StoneShovel,
    StringItem,
    TallGrass,
    LavaSide0,
    LavaSide1,
    LavaSide2,
    LavaSide3,
    LavaSide4,
    LavaSide5,
    TNTSide,
    TNTTop,
    TNTBottom,
    Blank,
    TorchSide,
    TorchTop,
    TorchBottom,
    Vines,
    WaterBucket,
    SpiderWeb,
    WetFarmland,
    Wheat0,
    Wheat1,
    Wheat2,
    Wheat3,
    Wheat4,
    Wheat5,
    Wheat6,
    Wheat7,
    OakWood,
    WoodAxe,
    WoodHoe,
    WoodPickaxe,
    WoodPressurePlateFace,
    WoodPressurePlateSide,
    WoodShovel,
    Wool;
    
    static this()
    {
		ActivatorRailOff = new immutable(TextureAtlas)(0, 0, 16, 16);
		ActivatorRailOn = new immutable(TextureAtlas)(16, 0, 16, 16);
		BedHead = new immutable(TextureAtlas)(32, 0, 16, 16);
		BedFoot = new immutable(TextureAtlas)(48, 0, 16, 16);
		BedTopSide = new immutable(TextureAtlas)(64, 0, 16, 16);
		BedTopLeftSide = new immutable(TextureAtlas)(80, 0, 16, 16);
		BedTopRightSide = new immutable(TextureAtlas)(112, 0, 16, 16);
		BedBottom = new immutable(TextureAtlas)(128, 0, 16, 16);
		BedBottomLeftSide = new immutable(TextureAtlas)(96, 0, 16, 16);
		BedBottomRightSide = new immutable(TextureAtlas)(144, 0, 16, 16);
		BedBottomSide = new immutable(TextureAtlas)(160, 0, 16, 16);
		BedItem = new immutable(TextureAtlas)(176, 0, 16, 16);
		Font8x8 = new immutable(TextureAtlas)(128, 128, 128, 128);
		Shockwave = new immutable(TextureAtlas)(0, 128, 128, 128);
		Bedrock = new immutable(TextureAtlas)(192, 0, 16, 16);
		BirchLeaves = new immutable(TextureAtlas)(208, 0, 16, 16);
		BirchPlank = new immutable(TextureAtlas)(224, 0, 16, 16);
		BirchSapling = new immutable(TextureAtlas)(240, 0, 16, 16);
		BirchWood = new immutable(TextureAtlas)(0, 16, 16, 16);
		WoodEnd = new immutable(TextureAtlas)(16, 16, 16, 16);
		BlazePowder = new immutable(TextureAtlas)(32, 16, 16, 16);
		BlazeRod = new immutable(TextureAtlas)(48, 16, 16, 16);
		Bone = new immutable(TextureAtlas)(64, 16, 16, 16);
		BoneMeal = new immutable(TextureAtlas)(80, 16, 16, 16);
		Bow = new immutable(TextureAtlas)(96, 16, 16, 16);
		BrownMushroom = new immutable(TextureAtlas)(112, 16, 16, 16);
		Bucket = new immutable(TextureAtlas)(128, 16, 16, 16);
		CactusSide = new immutable(TextureAtlas)(144, 16, 16, 16);
		CactusBottom = new immutable(TextureAtlas)(160, 16, 16, 16);
		CactusTop = new immutable(TextureAtlas)(176, 16, 16, 16);
		CactusGreen = new immutable(TextureAtlas)(192, 16, 16, 16);
		ChestSide = new immutable(TextureAtlas)(208, 16, 16, 16);
		ChestTop = new immutable(TextureAtlas)(224, 16, 16, 16);
		ChestFront = new immutable(TextureAtlas)(240, 16, 16, 16);
		CobbleStone = new immutable(TextureAtlas)(0, 32, 16, 16);
		Coal = new immutable(TextureAtlas)(16, 32, 16, 16);
		CoalOre = new immutable(TextureAtlas)(32, 32, 16, 16);
		CocoaSmallSide = new immutable(TextureAtlas)(48, 32, 16, 16);
		CocoaSmallTop = new immutable(TextureAtlas)(64, 32, 16, 16);
		CocoaSmallStem = new immutable(TextureAtlas)(80, 32, 16, 16);
		CocoaMediumSide = new immutable(TextureAtlas)(96, 32, 16, 16);
		CocoaMediumTop = new immutable(TextureAtlas)(112, 32, 16, 16);
		CocoaMediumStem = new immutable(TextureAtlas)(128, 32, 16, 16);
		CocoaLargeSide = new immutable(TextureAtlas)(144, 32, 16, 16);
		CocoaLargeTop = new immutable(TextureAtlas)(160, 32, 16, 16);
		CocoaLargeStem = new immutable(TextureAtlas)(176, 32, 16, 16);
		CocoaBeans = new immutable(TextureAtlas)(192, 32, 16, 16);
		DeadBush = new immutable(TextureAtlas)(208, 32, 16, 16);
		DandelionYellow = new immutable(TextureAtlas)(224, 32, 16, 16);
		Dandelion = new immutable(TextureAtlas)(240, 32, 16, 16);
		CyanDye = new immutable(TextureAtlas)(0, 48, 16, 16);
		Delete0 = new immutable(TextureAtlas)(16, 48, 16, 16);
		Delete1 = new immutable(TextureAtlas)(32, 48, 16, 16);
		Delete2 = new immutable(TextureAtlas)(48, 48, 16, 16);
		Delete3 = new immutable(TextureAtlas)(64, 48, 16, 16);
		Delete4 = new immutable(TextureAtlas)(80, 48, 16, 16);
		Delete5 = new immutable(TextureAtlas)(96, 48, 16, 16);
		Delete6 = new immutable(TextureAtlas)(112, 48, 16, 16);
		Delete7 = new immutable(TextureAtlas)(128, 48, 16, 16);
		Delete8 = new immutable(TextureAtlas)(144, 48, 16, 16);
		Delete9 = new immutable(TextureAtlas)(160, 48, 16, 16);
		DetectorRailOff = new immutable(TextureAtlas)(176, 48, 16, 16);
		DetectorRailOn = new immutable(TextureAtlas)(192, 48, 16, 16);
		Diamond = new immutable(TextureAtlas)(208, 48, 16, 16);
		DiamondAxe = new immutable(TextureAtlas)(224, 48, 16, 16);
		DiamondHoe = new immutable(TextureAtlas)(240, 48, 16, 16);
		DiamondOre = new immutable(TextureAtlas)(0, 64, 16, 16);
		DiamondPickaxe = new immutable(TextureAtlas)(16, 64, 16, 16);
		DiamondShovel = new immutable(TextureAtlas)(32, 64, 16, 16);
		Dirt = new immutable(TextureAtlas)(48, 64, 16, 16);
		DirtMask = new immutable(TextureAtlas)(64, 64, 16, 16);
		DispenserSide = new immutable(TextureAtlas)(80, 64, 16, 16);
		DispenserTop = new immutable(TextureAtlas)(96, 64, 16, 16);
		DropperSide = new immutable(TextureAtlas)(112, 64, 16, 16);
		DropperTop = new immutable(TextureAtlas)(128, 64, 16, 16);
		DispenserDropperPistonFurnaceFrame = new immutable(TextureAtlas)(144, 64, 16, 16);
		Emerald = new immutable(TextureAtlas)(160, 48, 16, 16);
		EmeraldOre = new immutable(TextureAtlas)(176, 64, 16, 16);
		PistonBaseSide = new immutable(TextureAtlas)(192, 64, 16, 16);
		PistonBaseTop = new immutable(TextureAtlas)(208, 64, 16, 16);
		PistonHeadSide = new immutable(TextureAtlas)(224, 64, 16, 16);
		PistonHeadFace = new immutable(TextureAtlas)(240, 64, 16, 16);
		PistonHeadBase = new immutable(TextureAtlas)(0, 80, 16, 16);
		StickyPistonHeadFace = new immutable(TextureAtlas)(16, 80, 16, 16);
		FarmlandSide = new immutable(TextureAtlas)(32, 80, 16, 16);
		FarmlandTop = new immutable(TextureAtlas)(48, 80, 16, 16);
		Fire0 = new immutable(TextureAtlas)(64, 80, 16, 16);
		Fire1 = new immutable(TextureAtlas)(80, 80, 16, 16);
		Fire2 = new immutable(TextureAtlas)(96, 80, 16, 16);
		Fire3 = new immutable(TextureAtlas)(112, 80, 16, 16);
		Fire4 = new immutable(TextureAtlas)(128, 80, 16, 16);
		Fire5 = new immutable(TextureAtlas)(144, 80, 16, 16);
		Fire6 = new immutable(TextureAtlas)(160, 80, 16, 16);
		Fire7 = new immutable(TextureAtlas)(176, 80, 16, 16);
		Flint = new immutable(TextureAtlas)(192, 80, 16, 16);
		FlintAndSteel = new immutable(TextureAtlas)(208, 80, 16, 16);
		FurnaceFrontOff = new immutable(TextureAtlas)(224, 80, 16, 16);
		FurnaceSide = new immutable(TextureAtlas)(240, 80, 16, 16);
		FurnaceFrontOn = new immutable(TextureAtlas)(0, 96, 16, 16);
		WorkBenchTop = new immutable(TextureAtlas)(16, 96, 16, 16);
		WorkBenchSide0 = new immutable(TextureAtlas)(32, 96, 16, 16);
		WorkBenchSide1 = new immutable(TextureAtlas)(48, 96, 16, 16);
		Glass = new immutable(TextureAtlas)(64, 96, 16, 16);
		GoldAxe = new immutable(TextureAtlas)(80, 96, 16, 16);
		GoldHoe = new immutable(TextureAtlas)(96, 96, 16, 16);
		GoldIngot = new immutable(TextureAtlas)(112, 96, 16, 16);
		GoldOre = new immutable(TextureAtlas)(128, 96, 16, 16);
		GoldPickaxe = new immutable(TextureAtlas)(144, 96, 16, 16);
		GoldShovel = new immutable(TextureAtlas)(160, 96, 16, 16);
		GrassMask = new immutable(TextureAtlas)(176, 96, 16, 16);
		GrassTop = new immutable(TextureAtlas)(192, 96, 16, 16);
		Gravel = new immutable(TextureAtlas)(208, 96, 16, 16);
		GrayDye = new immutable(TextureAtlas)(224, 96, 16, 16);
		Gunpowder = new immutable(TextureAtlas)(240, 96, 16, 16);
		HopperRim = new immutable(TextureAtlas)(0, 112, 16, 16);
		HopperInside = new immutable(TextureAtlas)(16, 112, 16, 16);
		HopperSide = new immutable(TextureAtlas)(32, 112, 16, 16);
		HopperBigBottom = new immutable(TextureAtlas)(48, 112, 16, 16);
		HopperMediumBottom = new immutable(TextureAtlas)(64 + 4, 112 + 4, 8, 8);
		HopperSmallBottom = new immutable(TextureAtlas)(64, 112, 4, 4);
		HopperItem = new immutable(TextureAtlas)(80, 112, 16, 16);
		HotBarBox = new immutable(TextureAtlas)(256, 236, 20, 20);
		InkSac = new immutable(TextureAtlas)(96, 112, 16, 16);
		IronAxe = new immutable(TextureAtlas)(112, 112, 16, 16);
		IronHoe = new immutable(TextureAtlas)(128, 112, 16, 16);
		IronIngot = new immutable(TextureAtlas)(144, 112, 16, 16);
		IronOre = new immutable(TextureAtlas)(160, 112, 16, 16);
		IronPickaxe = new immutable(TextureAtlas)(176, 112, 16, 16);
		IronShovel = new immutable(TextureAtlas)(192, 112, 16, 16);
		JungleLeaves = new immutable(TextureAtlas)(208, 112, 16, 16);
		JunglePlank = new immutable(TextureAtlas)(224, 112, 16, 16);
		JungleSapling = new immutable(TextureAtlas)(240, 112, 16, 16);
		JungleWood = new immutable(TextureAtlas)(256, 0, 16, 16);
		Ladder = new immutable(TextureAtlas)(256 + 16 * 1, 16 * 0, 16, 16);
		LapisLazuli = new immutable(TextureAtlas)(256 + 16 * 2, 16 * 0, 16, 16);
		LapisLazuliOre = new immutable(TextureAtlas)(256 + 16 * 3, 16 * 0, 16, 16);
		WheatItem = new immutable(TextureAtlas)(256 + 16 * 4, 16 * 0, 16, 16);
		LavaBucket = new immutable(TextureAtlas)(256 + 16 * 5, 16 * 0, 16, 16);
		OakLeaves = new immutable(TextureAtlas)(256 + 16 * 6, 16 * 0, 16, 16);
		LeverBaseBigSide = new immutable(TextureAtlas)(256 + 16 * 7, 16 * 0, 8, 3);
		LeverBaseSmallSide = new immutable(TextureAtlas)(256 + 16 * 7, 16 * 0 + 3, 6, 3);
		LeverBaseTop = new immutable(TextureAtlas)(256 + 16 * 7, 16 * 0 + 6, 8, 6);
		LeverHandleSide = new immutable(TextureAtlas)(256 + 16 * 7 + 8, 16 * 0, 2, 8);
		LeverHandleTop = new immutable(TextureAtlas)(256 + 16 * 7 + 12, 16 * 0, 2, 2);
		LeverHandleBottom = new immutable(TextureAtlas)(256 + 16 * 7 + 10, 16 * 0, 2, 2);
		LightBlueDye = new immutable(TextureAtlas)(384, 0, 16, 16);
		LightGrayDye = new immutable(TextureAtlas)(400, 0, 16, 16);
		LimeDye = new immutable(TextureAtlas)(416, 0, 16, 16);
		MagentaDye = new immutable(TextureAtlas)(432, 0, 16, 16);
		MinecartInsideSide = new immutable(TextureAtlas)(448, 0, 16, 16);
		MinecartInsideBottom = new immutable(TextureAtlas)(464, 0, 16, 16);
		MinecartItem = new immutable(TextureAtlas)(480, 0, 16, 16);
		MinecartOutsideLeftRight = new immutable(TextureAtlas)(496, 0, 16, 16);
		MinecartOutsideFrontBack = new immutable(TextureAtlas)(256, 16, 16, 16);
		MinecartOutsideBottom = new immutable(TextureAtlas)(272, 16, 16, 16);
		MinecartOutsideTop = new immutable(TextureAtlas)(288, 16, 16, 16);
		MinecartWithChest = new immutable(TextureAtlas)(304, 16, 16, 16);
		MinecartWithHopper = new immutable(TextureAtlas)(320, 16, 16, 16);
		MinecartWithTNT = new immutable(TextureAtlas)(336, 16, 16, 16);
		MobSpawner = new immutable(TextureAtlas)(352, 16, 16, 16);
		OrangeDye = new immutable(TextureAtlas)(368, 16, 16, 16);
		WaterSide0 = new immutable(TextureAtlas)(384 + 16 * 0, 16, 16, 16);
		WaterSide1 = new immutable(TextureAtlas)(384 + 16 * 1, 16, 16, 16);
		WaterSide2 = new immutable(TextureAtlas)(384 + 16 * 2, 16, 16, 16);
		WaterSide3 = new immutable(TextureAtlas)(384 + 16 * 3, 16, 16, 16);
		WaterSide4 = new immutable(TextureAtlas)(384 + 16 * 4, 16, 16, 16);
		WaterSide5 = new immutable(TextureAtlas)(384 + 16 * 5, 16, 16, 16);
		Obsidian = new immutable(TextureAtlas)(480, 16, 16, 16);
		ParticleSmoke0 = new immutable(TextureAtlas)(256 + 8 * 0, 128, 8, 8);
		ParticleSmoke1 = new immutable(TextureAtlas)(256 + 8 * 1, 128, 8, 8);
		ParticleSmoke2 = new immutable(TextureAtlas)(256 + 8 * 2, 128, 8, 8);
		ParticleSmoke3 = new immutable(TextureAtlas)(256 + 8 * 3, 128, 8, 8);
		ParticleSmoke4 = new immutable(TextureAtlas)(256 + 8 * 4, 128, 8, 8);
		ParticleSmoke5 = new immutable(TextureAtlas)(256 + 8 * 5, 128, 8, 8);
		ParticleSmoke6 = new immutable(TextureAtlas)(256 + 8 * 6, 128, 8, 8);
		ParticleSmoke7 = new immutable(TextureAtlas)(256 + 8 * 7, 128, 8, 8);
		ParticleFire0 = new immutable(TextureAtlas)(320, 128, 8, 8);
		ParticleFire1 = new immutable(TextureAtlas)(328, 128, 8, 8);
		PinkDye = new immutable(TextureAtlas)(496, 16, 16, 16);
		PinkStone = new immutable(TextureAtlas)(256, 16, 16, 16);
		PistonShaft = new immutable(TextureAtlas)(276, 244, 2, 12);
		OakPlank = new immutable(TextureAtlas)(272, 32, 16, 16);
		PoweredRailOff = new immutable(TextureAtlas)(288, 32, 16, 16);
		PoweredRailOn = new immutable(TextureAtlas)(304, 32, 16, 16);
		PurpleDye = new immutable(TextureAtlas)(320, 32, 16, 16);
		PurplePortal = new immutable(TextureAtlas)(336, 32, 16, 16);
		Quartz = new immutable(TextureAtlas)(352, 32, 16, 16);
		Rail = new immutable(TextureAtlas)(368, 32, 16, 16);
		RailCurve = new immutable(TextureAtlas)(384, 32, 16, 16);
		RedMushroom = new immutable(TextureAtlas)(400, 32, 16, 16);
		BlockOfRedstone = new immutable(TextureAtlas)(416, 32, 16, 16);
		RedstoneComparatorOff = new immutable(TextureAtlas)(432, 32, 16, 16);
		RedstoneComparatorOn = new immutable(TextureAtlas)(448, 32, 16, 16);
		RedstoneComparatorRepeatorSide = new immutable(TextureAtlas)(464, 46, 16, 2);
		RedstoneShortTorchSideOn = new immutable(TextureAtlas)(464, 32, 8, 12);
		RedstoneShortTorchSideOff = new immutable(TextureAtlas)(472, 32, 8, 12);
		RedstoneDust0 = new immutable(TextureAtlas)(480, 32, 16, 16);
		RedstoneDust1 = new immutable(TextureAtlas)(496, 32, 16, 16);
		RedstoneDust2Corner = new immutable(TextureAtlas)(256, 48, 16, 16);
		RedstoneDust2Across = new immutable(TextureAtlas)(272, 48, 16, 16);
		RedstoneDust3 = new immutable(TextureAtlas)(288, 48, 16, 16);
		RedstoneDust4 = new immutable(TextureAtlas)(304, 48, 16, 16);
		RedstoneDustItem = new immutable(TextureAtlas)(320, 48, 16, 16);
		RedstoneRepeatorBarSide = new immutable(TextureAtlas)(336, 48, 12, 2);
		RedstoneRepeatorBarTopBottom = new immutable(TextureAtlas)(336, 50, 12, 2);
		RedstoneRepeatorBarEnd = new immutable(TextureAtlas)(336, 52, 2, 2);
		RedstoneOre = new immutable(TextureAtlas)(352, 48, 16, 16);
		ActiveRedstoneOre = new immutable(TextureAtlas)(368, 48, 16, 16);
		RedstoneRepeatorOff = new immutable(TextureAtlas)(384, 48, 16, 16);
		RedstoneRepeatorOn = new immutable(TextureAtlas)(400, 48, 16, 16);
		RedstoneTorchSideOn = new immutable(TextureAtlas)(416, 48, 16, 16);
		RedstoneTorchSideOff = new immutable(TextureAtlas)(432, 48, 16, 16);
		RedstoneTorchTopOn = new immutable(TextureAtlas)(423, 54, 2, 2);
		RedstoneTorchTopOff = new immutable(TextureAtlas)(439, 54, 2, 2);
		RedstoneTorchBottomOn = new immutable(TextureAtlas)(423, 62, 2, 2);
		RedstoneTorchBottomOff = new immutable(TextureAtlas)(439, 62, 2, 2);
		Rose = new immutable(TextureAtlas)(448, 48, 16, 16);
		RoseRed = new immutable(TextureAtlas)(464, 48, 16, 16);
		Sand = new immutable(TextureAtlas)(480, 48, 16, 16);
		OakSapling = new immutable(TextureAtlas)(496, 48, 16, 16);
		WheatSeeds = new immutable(TextureAtlas)(256, 64, 16, 16);
		Shears = new immutable(TextureAtlas)(272, 64, 16, 16);
		Slime = new immutable(TextureAtlas)(288, 64, 16, 16);
		Snow = new immutable(TextureAtlas)(304, 64, 16, 16);
		SnowBall = new immutable(TextureAtlas)(320, 64, 16, 16);
		SnowGrass = new immutable(TextureAtlas)(336, 64, 16, 16);
		SpruceLeaves = new immutable(TextureAtlas)(352, 64, 16, 16);
		SprucePlank = new immutable(TextureAtlas)(368, 64, 16, 16);
		SpruceSapling = new immutable(TextureAtlas)(384, 64, 16, 16);
		SpruceWood = new immutable(TextureAtlas)(400, 64, 16, 16);
		Stick = new immutable(TextureAtlas)(416, 64, 16, 16);
		Stone = new immutable(TextureAtlas)(432, 64, 16, 16);
		StoneAxe = new immutable(TextureAtlas)(448, 64, 16, 16);
		StoneButtonFace = new immutable(TextureAtlas)(464, 64, 6, 4);
		StoneButtonLongEdge = new immutable(TextureAtlas)(464, 68, 6, 2);
		StoneButtonShortEdge = new immutable(TextureAtlas)(470, 64, 2, 4);
		WoodButtonFace = new immutable(TextureAtlas)(464, 72, 6, 4);
		WoodButtonLongEdge = new immutable(TextureAtlas)(464, 76, 6, 2);
		WoodButtonShortEdge = new immutable(TextureAtlas)(470, 72, 2, 4);
		StoneHoe = new immutable(TextureAtlas)(480, 64, 16, 16);
		StonePickaxe = new immutable(TextureAtlas)(496, 64, 16, 16);
		StonePressurePlateFace = new immutable(TextureAtlas)(256, 80, 16, 16);
		StonePressurePlateSide = new immutable(TextureAtlas)(272, 80, 16, 2);
		StoneShovel = new immutable(TextureAtlas)(288, 80, 16, 16);
		StringItem = new immutable(TextureAtlas)(304, 80, 16, 16);
		TallGrass = new immutable(TextureAtlas)(320, 80, 16, 16);
		LavaSide0 = new immutable(TextureAtlas)(336 + 16 * 0, 80, 16, 16);
		LavaSide1 = new immutable(TextureAtlas)(336 + 16 * 1, 80, 16, 16);
		LavaSide2 = new immutable(TextureAtlas)(336 + 16 * 2, 80, 16, 16);
		LavaSide3 = new immutable(TextureAtlas)(336 + 16 * 3, 80, 16, 16);
		LavaSide4 = new immutable(TextureAtlas)(336 + 16 * 4, 80, 16, 16);
		LavaSide5 = new immutable(TextureAtlas)(336 + 16 * 5, 80, 16, 16);
		TNTSide = new immutable(TextureAtlas)(432, 80, 16, 16);
		TNTTop = new immutable(TextureAtlas)(448, 80, 16, 16);
		TNTBottom = new immutable(TextureAtlas)(464, 80, 16, 16);
		Blank = new immutable(TextureAtlas)(480, 80, 16, 16);
		TorchSide = new immutable(TextureAtlas)(496, 80, 16, 16);
		TorchTop = new immutable(TextureAtlas)(503, 86, 2, 2);
		TorchBottom = new immutable(TextureAtlas)(503, 94, 2, 2);
		Vines = new immutable(TextureAtlas)(256, 96, 16, 16);
		WaterBucket = new immutable(TextureAtlas)(272, 96, 16, 16);
		SpiderWeb = new immutable(TextureAtlas)(288, 96, 16, 16);
		WetFarmland = new immutable(TextureAtlas)(304, 96, 16, 16);
		Wheat0 = new immutable(TextureAtlas)(320 + 16 * 0, 96, 16, 16);
		Wheat1 = new immutable(TextureAtlas)(320 + 16 * 1, 96, 16, 16);
		Wheat2 = new immutable(TextureAtlas)(320 + 16 * 2, 96, 16, 16);
		Wheat3 = new immutable(TextureAtlas)(320 + 16 * 3, 96, 16, 16);
		Wheat4 = new immutable(TextureAtlas)(320 + 16 * 4, 96, 16, 16);
		Wheat5 = new immutable(TextureAtlas)(320 + 16 * 5, 96, 16, 16);
		Wheat6 = new immutable(TextureAtlas)(320 + 16 * 6, 96, 16, 16);
		Wheat7 = new immutable(TextureAtlas)(320 + 16 * 7, 96, 16, 16);
		OakWood = new immutable(TextureAtlas)(448, 96, 16, 16);
		WoodAxe = new immutable(TextureAtlas)(464, 96, 16, 16);
		WoodHoe = new immutable(TextureAtlas)(480, 96, 16, 16);
		WoodPickaxe = new immutable(TextureAtlas)(496, 96, 16, 16);
		WoodPressurePlateFace = new immutable(TextureAtlas)(256, 112, 16, 16);
		WoodPressurePlateSide = new immutable(TextureAtlas)(272, 82, 16, 2);
		WoodShovel = new immutable(TextureAtlas)(272, 112, 16, 16);
		Wool = new immutable(TextureAtlas)(288, 112, 16, 16);
	}
}
